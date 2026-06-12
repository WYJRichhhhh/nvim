-- 调用本机 claude CLI 做「即问即答」式的一次性交互(无多轮、无历史存储)。
--
-- 为什么落在 core/ 而非 plugins/:本仓库约定 plugins/ 只放第三方 lazy 插件规格,
-- 自写的纯逻辑功能(见 structure_search)统一放 core/、键位在 core/keymaps.lua 注入。
--
-- 四个设计要点,理解了就知道为什么这么写:
--   1. 交互方式固定为「待处理文本走 stdin 当上下文,指令走 `claude -p` 参数」。
--      这样无需把大段选区/文件内容拼进命令行,天然规避转义与命令行长度限制。
--   2. 全程 vim.system 异步:先弹一个「请求中」占位浮窗,claude 返回后就地替换内容,
--      绝不阻塞编辑(claude 一次响应可能要好几秒)。
--   3. 流式输出:用 `--output-format=stream-json --include-partial-messages` 让 claude
--      逐 token 吐 NDJSON,stdout 回调里挑出 text_delta 实时追加进 buffer,边生成边看,
--      而非干等整段返回。
--   4. 关键的「渲染时机」:流式期间 buffer 保持纯文本(不挂 ft),只在请求完整结束、
--      文本稳定后才一次性设 ft=markdown 触发 render-markdown / treesitter 渲染。
--      这不是偷懒——treesitter 高亮器是全局注册的 decoration provider,若在流式频繁
--      改写的 buffer 上跑代码围栏注入解析,会撞上「异步解析期间文本又变了」的失效节点
--      (node:range() 报 nil),进而把整个 highlighter provider 搞挂,连带正在编辑的
--      代码文件也掉高亮、刷报错。延后到稳定文本上渲染一次,这个竞态就不存在了。
--   按 q 关闭,并顺手 kill 掉仍在跑的请求(没必要让一个已经不想看的回答继续占着进程)。

local M = {}

-- 翻译模式的指令模板。固定走 -p 参数下发,选中文本走 stdin。要求严格结构,避免寒暄。
-- 「谐音发音」一项按字面理解为「用汉语拼音模拟英文读音以助记」(如 banana → 巴娜娜)。
local TRANSLATE_PROMPT = [[
你是一位英语词汇老师。stdin 里是需要讲解的英文单词或短语。请用简体中文、Markdown 格式输出讲解,不要任何寒暄或多余说明,严格包含以下部分:

1. 一级标题:原词本身
2. **音标**:分别给出英式 /.../ 与美式 /.../ 音标
3. **词根词缀**:拆解词根/词缀并说明各自含义;无明显词根则给记忆点
4. **谐音发音**:用汉语拼音模拟该词读音以帮助记忆(如 banana → 巴娜娜)
5. **中文含义**:按词性分条列出
6. **近义词辨析**:列出近义词/同义词,并逐一说明它们与原词在使用场景上的区别
7. **常用例句**:给出 3 个不同场景的例句,每条按「英文 —— 中文」对照

若 stdin 是句子或段落而非单词,先给出地道的中文翻译,再挑出其中重点词按上面方式简要讲解。
]]

-- 浮窗 + 运行态:同一时刻只维持一个结果浮窗;handle 是进行中的 vim.system 句柄,
-- 关窗时据此 kill。聚成一个表而非散几个上值,意图更清楚。
--   acc      流式累积的纯文本,token 到达时追加,结束时据此判空/善后。
--   pending  stdout 可能在一次回调里送来跨行的半截 NDJSON,这里暂存「最后一段不完整行」,
--            与下次回调拼接后再解析,避免把半行 JSON 喂给 decode。
--   started  是否已收到首个 token——用于把占位提示「正在请求」替换成真正的首段输出。
local state = { win = nil, buf = nil, handle = nil, acc = "", pending = "", started = false }

-- 关闭浮窗:先 kill 仍在跑的请求(若有),再关窗。两处都用 is_valid/pcall 兜底,
-- 因为用户可能已用别的方式关掉窗、或请求已自然结束。
local function close()
    if state.handle then
        pcall(function() state.handle:kill(9) end)
        state.handle = nil
    end
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win, state.buf = nil, nil
end

-- 把文本写进浮窗 buffer。结果到来时也走这里就地替换,故每次都先开 modifiable。
local function set_lines(buf, text)
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
        return
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
    vim.bo[buf].modifiable = false
end

-- 定稿:流式结束后才挂 ft=markdown,触发 render-markdown / treesitter 渲染。
-- 故意延后到此刻而非建窗时就挂——见文件头第 4 点:流式期间 buffer 反复改写会让 treesitter
-- 的代码围栏注入解析撞上失效节点,把全局 highlighter provider 搞挂,连累正在编辑的代码文件。
-- 文本稳定后渲染一次则无此竞态。set_lines 会把 modifiable 关回去,设 ft 不受影响。
local function finalize(buf)
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
        return
    end
    vim.bo[buf].filetype = "markdown"
end

-- 居中浮窗:宽度取「列宽 80% 与 100 列」的较小者(翻译卡片不必铺满整屏),高度 80%。
-- 注意此处不设 ft——流式期间保持纯文本,渲染交给定稿时的 finalize()。buffer-local q 关闭。
-- 开新窗前先 close() 旧窗,保证「单浮窗」语义。
local function open_float(title)
    close()
    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.min(100, math.floor(vim.o.columns * 0.8))
    local height = math.floor(vim.o.lines * 0.8)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " " .. title .. " ",
        title_pos = "center",
    })
    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
    vim.wo[win].conceallevel = 2
    vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, desc = "关闭" })
    state.win, state.buf = win, buf
    return buf
end

-- 取可视选区文本。只在可视模式(v/V/<C-v>)有意义;getregion 按当前模式自动处理
-- 字符/行/块选区。取完位置后立即退出可视模式,避免浮窗在选区高亮残留下打开。
local function visual_selection()
    local mode = vim.fn.mode()
    if not mode:match("^[vV\22]") then
        return nil
    end
    local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    return table.concat(lines, "\n")
end

-- 处理 stream-json 的一行 NDJSON:只关心携带正文增量的事件,其余(init/status/usage 等)
-- 一律忽略。命中 text_delta 就把增量追加进 state.acc 并刷新 buffer。返回是否产生了正文增量。
-- 解析失败(半截行或非 JSON)静默跳过——stdout 分块本就可能切碎一行,交给上层的 pending 拼接。
local function handle_event(line)
    line = vim.trim(line)
    if line == "" then
        return false
    end
    local ok, ev = pcall(vim.json.decode, line)
    if not (ok and type(ev) == "table") then
        return false
    end
    -- 逐 token 的增量都包在 type=stream_event 的内层 event 里,形如
    -- {type:"content_block_delta", delta:{type:"text_delta", text:"..."}}。
    if ev.type ~= "stream_event" or type(ev.event) ~= "table" then
        return false
    end
    local inner = ev.event
    if inner.type == "content_block_delta"
        and type(inner.delta) == "table"
        and inner.delta.type == "text_delta"
        and type(inner.delta.text) == "string"
    then
        state.acc = state.acc .. inner.delta.text
        return true
    end
    return false
end

-- 统一的交互入口:弹占位浮窗 → 流式跑 claude → 逐 token 追加 → 结束后定稿渲染。
-- opts = { title, instruction, stdin }。
-- stdout 回调跑在 libuv 线程,任何 nvim API 都得 vim.schedule 切回主线程;且每次都先判
-- buffer 是否还在(用户可能已按 q 关掉),失效就丢弃。
local function interact(opts)
    if vim.fn.executable("claude") == 0 then
        vim.notify("未找到 claude 命令,请确认已安装并在 PATH 中", vim.log.levels.ERROR)
        return
    end
    local buf = open_float(opts.title)
    set_lines(buf, "⏳ 正在请求 claude……(按 q 取消并关闭)")
    state.acc, state.pending, state.started = "", "", false

    -- stdout 分块到达,先与上一块残留的 pending 拼接,再按换行切行;最后一段大概率是
    -- 不完整行(下一块的开头),留到 pending 等待续上。有正文增量才刷新 buffer。
    local function on_stdout(_, data)
        if not data then
            return
        end
        vim.schedule(function()
            if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
                return
            end
            local chunk = state.pending .. data
            local parts = vim.split(chunk, "\n", { plain = true })
            state.pending = table.remove(parts) -- 末段残留,等下次拼接
            local grew = false
            for _, line in ipairs(parts) do
                if handle_event(line) then
                    grew = true
                end
            end
            if grew then
                state.started = true
                set_lines(state.buf, state.acc)
                -- 回答超过窗高时跟随滚到底,否则新生成的 token 会停在视野外。
                -- 仅当浮窗仍是当前窗时移动光标(用户可能切到别处),用 nvim_win_set_cursor
                -- 把光标顶到最后一行即可带动滚动。
                if state.win and vim.api.nvim_win_is_valid(state.win) then
                    local last = vim.api.nvim_buf_line_count(state.buf)
                    pcall(vim.api.nvim_win_set_cursor, state.win, { last, 0 })
                end
            end
        end)
    end

    state.handle = vim.system(
        {
            "claude", "-p", opts.instruction,
            "--output-format", "stream-json",
            "--include-partial-messages",
            "--verbose", -- stream-json 模式下 CLI 要求开 verbose,否则拒绝输出
        },
        { stdin = opts.stdin, text = true, stdout = on_stdout },
        function(obj)
            vim.schedule(function()
                state.handle = nil
                if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
                    return -- 浮窗已被关闭,丢弃结果
                end
                if obj.code ~= 0 then
                    set_lines(state.buf, "claude 调用失败(exit " .. obj.code .. "):\n\n" .. (obj.stderr or ""))
                    finalize(state.buf)
                    return
                end
                local out = vim.trim(state.acc)
                set_lines(state.buf, out ~= "" and out or "(claude 没有返回内容)")
                finalize(state.buf) -- 文本已稳定,此刻才挂 ft 触发渲染
            end)
        end
    )
end

-- 翻译选中内容(可视模式)。结果是一张词汇讲解卡片,格式见 TRANSLATE_PROMPT。
function M.translate()
    local sel = visual_selection()
    if not sel or vim.trim(sel) == "" then
        vim.notify("请先在可视模式选中要翻译的内容", vim.log.levels.WARN)
        return
    end
    interact({ title = "翻译", stdin = sel, instruction = TRANSLATE_PROMPT })
end

-- 以当前文件全文为上下文提问(普通模式)。用 vim.ui.input 弹输入框(已装 dressing.nvim,
-- 观感是浮窗),用户输入问题后,把整文件内容 + 文件名/类型走 stdin、问题走指令。
function M.ask()
    local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    if vim.trim(content) == "" then
        vim.notify("当前 buffer 为空,没有可作为上下文的内容", vim.log.levels.WARN)
        return
    end
    local name = vim.fn.expand("%:t")
    local ft = vim.bo.filetype
    -- start_mode="insert":仅这一次让 dressing 输入框开在插入模式。全局配置是
    -- start_in_insert=false(输入框默认停普通模式),但那样 IME 中文在普通模式不回显,
    -- 回车又拿到空串、走不到结果框。dressing 默认不读单次 opts,故在 dressing.lua 配了
    -- get_config 钩子:仅当调用方显式传 start_mode 时才覆盖,这里据此按调用切到 insert,
    -- 既修中文输入、又不动全局偏好。
    vim.ui.input({ prompt = "针对当前文件提问: ", start_mode = "insert" }, function(q)
        if not q or vim.trim(q) == "" then
            return
        end
        interact({
            title = "问答: " .. q,
            stdin = string.format(
                "文件名: %s\n语言: %s\n\n%s",
                name ~= "" and name or "(未命名)",
                ft ~= "" and ft or "(未知)",
                content
            ),
            instruction = string.format(
                "下面 stdin 是一个源代码/文本文件的完整内容。请基于它用简体中文回答这个问题,"
                    .. "回答用 Markdown 格式,必要时引用相关代码片段:\n\n%s",
                q
            ),
        })
    end)
end

return M
