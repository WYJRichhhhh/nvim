-- ============================================================================
-- 键位定义准则（新增/调整快捷键前先读这里）
--
-- 这套键位围绕三个目标：同作用域不冲突、好记、够短。新键照此办理就能自然落到
-- 正确位置、不撞车，事后也能凭规律反推出键位。下面六条是「为什么这么放」。
--
-- 一、按作用域分三层放置（决定「这个键写在哪个文件」）
--   1. 全局键     → 本文件 core/keymaps.lua。任何 buffer 都该生效的通用操作。
--   2. 语言专属键 → ftplugin/<语言>.lua，用 { buffer = true } 设成 buffer-local。
--                   只在该语言下才有意义的（如「调试当前测试方法」）放这里：既不
--                   污染全局，也不会在别的文件里遮挡同名全局键。
--   3. 插件专属键 → 插件 spec（lua/plugins/<插件>.lua）的 keys/config，随插件懒加载。
--                   仅服务单个插件的键（git-tools 的 <leader>g*、minifiles 的
--                   <leader><leader>）放这。
--   反例：不要在 ft=xxx 的插件 config 里用「全局」vim.keymap.set 定义键——那样它
--   既不是 buffer-local 又散落在外，会和本文件同名键互相覆盖（调试键曾踩此坑，
--   已把通用 dap 键统一收回本文件）。
--
-- 二、单一事实来源：一个功能只绑一处键
--   同一动作只定义一次。跨语言要一致的（如「整理导入」<leader>oi）把触发逻辑收敛到
--   core/（见 core/imports.lua），各 ftplugin 只注入，绝不复制第二份实现。
--
-- 三、leader 前缀 = 语义命名空间，一个前缀只装一类，并在 which-key 登记
--   <leader> 后首字母按「功能英文首字母」分组，同类聚拢、异类不混：
--     f 查找(find)   g Git    d 调试(debug)   s 窗口(split)   h 书签(harpoon)
--     w 保存(write)  t 标签/主题   n 通知    c diff/合并   F 跳转(Hop)   o 整理(organize)
--   加新键先问「它属于哪一类」，落到对应前缀，并在 plugins/which-key.lua 标注分组。
--   不属于任何现有类时，宁可新开一个语义清晰的前缀，也别塞进不相干的前缀凑数
--   （曾把 HopWord 误放进 <leader>f 查找区，已移回跳转区 <leader>Fw）。
--
-- 四、助记：用功能英文缩写，能一字母不用两字母
--   键母取功能英文词首：b=breakpoint、c=continue、i=into、o=over、l=last……
--   大写 = 对应小写的「反向/更强」变体：do 单步跳过 ↔ dO 单步跳出；
--   db 切换断点 ↔ dB 条件断点 ↔ dC 清空全部断点。
--   多层子类用追加字母表达父子：dt = debug-test，dtc 测试类、dtm 测试方法。
--
-- 五、无 leader 单键留给高频、跨模式的「动作」
--   高频操作（移动/跳转/LSP）不挂 leader 以求最短：窗口 <C-hjkl>、缓冲区 H/L、
--   Hop s/S/f/F、LSP 跳转与动作 g*（gd/gr/ga…）、rn 重命名、宏 q…q + @。
--   占用无 leader 单键前务必确认没牺牲常用原生键——曾用 q 清高亮，反而废掉了宏录制，
--   现已把清高亮改回 <Esc>，q 还给宏。
--
-- 六、不一致就改齐
--   同类键用同一套写法（都带 desc、同一命名风格）。改一处约定，回头扫一遍同类，
--   别留新旧两种写法并存。
-- ============================================================================

-- 将 leader 键设为空格
vim.g.mapleader = " "

local keymap = vim.keymap

-- 通用键位 --------------------------------------------------------------------
-- 将 gh 映射到行首
keymap.set({ "n", "v" }, "gh", "^", { desc = "行首" })
keymap.set({ "n", "v" }, "gl", "$", { desc = "行尾" })
keymap.set({ "i" }, "jk", "<ESC>", { desc = "ESC" }) -- jk 退出插入模式
keymap.set({ "v" }, "q", "<ESC>", { desc = "ESC" }) -- q 退出可视模式
keymap.set("i", "<C-b>", "<ESC>^i", { desc = "行首" }) -- 跳到行首
keymap.set("i", "<C-e>", "<End>", { desc = "行尾" }) -- 跳到行尾
keymap.set("i", "<C-h>", "<Left>", { desc = "光标左移" }) -- 左移
keymap.set("i", "<C-l>", "<Right>", { desc = "光标右移" }) -- 右移
keymap.set("i", "<C-j>", "<Down>", { desc = "光标下移" }) -- 下移
keymap.set("i", "<C-k>", "<Up>", { desc = "光标上移" }) -- 上移
keymap.set("n", "<leader>wq", ":wq<CR>", { desc = "保存并退出" }) -- 保存并退出
keymap.set("n", "<leader>wa", ":wa<CR>", { desc = "保存全部" }) -- 保存全部
keymap.set("n", "<leader>qq", ":q!<CR>", { desc = "退出不保存" }) -- 退出不保存
keymap.set("n", "<leader>ww", ":w<CR>", { desc = "保存当前buffer" }) -- 保存
-- 用系统默认程序打开光标下的 URL。macOS 用 open，Linux 用 xdg-open，Windows 用 start。
-- 旧写法 `:!open` 是 macOS 专属，换到 Linux 会直接报命令找不到。
keymap.set("n", "gx", function()
    local url = vim.fn.expand("<cfile>")
    local opener = (jit.os == "OSX" and "open") or (jit.os == "Windows" and "start") or "xdg-open"
    vim.fn.jobstart({ opener, url }, { detach = true })
end, { desc = "用系统默认程序打开光标下的 url" }) -- 用系统默认程序打开光标下的 URL
-- 清除搜索高亮：用 <Esc> 触发。曾绑在 q 上，但那样既废掉宏录制(q{寄存器})，又因
-- 为存在更长的 qq 映射而让每次清高亮都等一个 timeoutlen。<Esc> 在普通模式本就空闲，
-- 顺手且无副作用。
keymap.set("n", "<Esc>", "<cmd>noh<CR>", { desc = "清除搜索高亮" })
keymap.set("n", "<leader>\\w", "<cmd>set wrap!<CR>", { desc = "切换自动换行" }) -- 切换自动换行
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "垂直分割窗口" }) -- 垂直分割窗口
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "水平分割窗口" }) -- 水平分割窗口
keymap.set("n", "<leader>se", "<C-w>=", { desc = "分割窗口等宽" }) -- 使分割窗口等宽
keymap.set("n", "<leader>sx", ":close<CR>", { desc = "关闭窗口" }) -- 关闭分割窗口
keymap.set("n", "<M-Up>", ":resize +5<cr>", { desc = "增加窗口高度" }) -- 增加窗口高度
keymap.set("n", "<M-Down>", ":resize -5<cr>", { desc = "减少窗口高度" }) -- 减少窗口高度
keymap.set("n", "<M-Left>", ":vertical resize -5<cr>", { desc = "减少窗口宽度" }) -- 减少窗口宽度
keymap.set("n", "<M-Right>", ":vertical resize +5<cr>", { desc = "增加窗口宽度" }) -- 增加窗口宽度
keymap.set("n", "<C-h>", "<C-w>h", { desc = "光标移动到左侧窗口" }) -- 向左移动
keymap.set("n", "<C-j>", "<C-w>j", { desc = "光标移动到下侧窗口" }) -- 向下移动
keymap.set("n", "<C-k>", "<C-w>k", { desc = "光标移动到上侧窗口" }) -- 向上移动
keymap.set("n", "<C-l>", "<C-w>l", { desc = "光标移动到右侧窗口" }) -- 向右移动

-- diff 相关键位 ---------------------------------------------------------------
keymap.set("n", "<leader>cc", ":diffput<CR>", { desc = "diff: 推送当前更改到对方" }) -- diff 时把当前侧更改推送到对方
keymap.set("n", "<leader>cj", ":diffget 1<CR>", { desc = "diff: 采用左侧(本地)更改" }) -- 合并时采用左侧(本地)更改
keymap.set("n", "<leader>ck", ":diffget 3<CR>", { desc = "diff: 采用右侧(远端)更改" }) -- 合并时采用右侧(远端)更改
keymap.set("n", "<leader>cn", "]c", { desc = "diff: 下一处差异" }) -- 下一处差异块
keymap.set("n", "<leader>cp", "[c", { desc = "diff: 上一处差异" }) -- 上一处差异块

-- Vim-maximizer ---------------------------------------------------------------
keymap.set("n", "<leader>sm", ":MaximizerToggle<CR>", { desc = "toggle最大化当前窗口" }) -- 切换当前窗口最大化

-- -- Nvim-tree 插件已禁用 替换为minifile
-- keymap.set("n", "<leader><leader>", ":NvimTreeToggle<CR>") -- 切换文件浏览器
-- keymap.set("n", "<leader>er", ":NvimTreeFocus<CR>") -- 切换焦点到文件浏览器
-- keymap.set("n", "<leader>ef", ":NvimTreeFindFile<CR>") -- 在文件浏览器中定位当前文件

-- Telescope -------------------------------------------------------------------

keymap.set("n", "<leader>ff", function()
    require("telescope.builtin").find_files()
end, { desc = "查找文件" })
keymap.set("n", "<leader>fg", function()
    require("telescope.builtin").live_grep()
end, { desc = "查找文本内容" })
keymap.set("n", "<leader>fb", function()
    require("telescope.builtin").buffers()
end, { desc = "在buffers中查找" })
keymap.set("n", "<leader>fh", function()
    require("telescope.builtin").help_tags()
end, { desc = "查找帮助文档" })
keymap.set("n", "<leader>fs", function()
    -- 类 PyCharm 结构搜索:树形观感(按 level 缩进)+ 实时模糊过滤。
    -- 自定义 picker 直接读 aerial 符号数据,实现见 core/structure_search.lua。
    -- 这是日常主力,占用更好按的小写键。
    require("core.structure_search").open()
end, { desc = "结构搜索(树形+模糊过滤)" })
keymap.set("n", "<leader>fS", function()
    -- 树状大纲浮窗:按 class → method 的父子层级缩进展示,并跟随光标高亮当前符号
    require("aerial").toggle()
end, { desc = "查看代码符号大纲(树状浮窗)" })
keymap.set("n", "<leader>fc", function()
    require("telescope.builtin").lsp_incoming_calls()
end, { desc = "通过LSP查找当前符号调用方" })
keymap.set("n", "<leader>ft", function()
    require("telescope.builtin").treesitter()
end, { desc = "查找语法树" })

keymap.set("n", "<leader>fd", function()
    require("telescope.builtin").diagnostics()
end, { desc = "查找诊断" })

keymap.set("n", "<leader>fn", function()
    -- telescope 模糊搜通知历史。归在 f(查找)区而非 n(通知)区:它本质是「在通知域里
    -- 模糊查找」,跟 fb/fd/fh/ft 同属 f+域首字母 的查找系列。nvim-notify 提供历史数据,
    -- 由 telescope 的 notify 扩展(见 plugins/telescope-nvim.lua 里的 load_extension)渲染。
    require("telescope").extensions.notify.notify()
end, { desc = "查找通知历史" })

-- Harpoon ---------------------------------------------------------------------
keymap.set("n", "<leader>ha", require("harpoon.mark").add_file, { desc = "添加书签" })
keymap.set("n", "<leader>hh", require("harpoon.ui").toggle_quick_menu, { desc = "打开书签列表" })
keymap.set("n", "<leader>h1", function()
    require("harpoon.ui").nav_file(1)
end, { desc = "打开书签1" })
keymap.set("n", "<leader>h2", function()
    require("harpoon.ui").nav_file(2)
end, { desc = "打开书签2" })
keymap.set("n", "<leader>h3", function()
    require("harpoon.ui").nav_file(3)
end, { desc = "打开书签3" })

keymap.set("n", "<leader>h4", function()
    require("harpoon.ui").nav_file(4)
end, { desc = "打开书签4" })

keymap.set("n", "<leader>h5", function()
    require("harpoon.ui").nav_file(5)
end, { desc = "打开书签5" })

keymap.set("n", "<leader>h6", function()
    require("harpoon.ui").nav_file(6)
end, { desc = "打开书签6" })

keymap.set("n", "<leader>h7", function()
    require("harpoon.ui").nav_file(7)
end, { desc = "打开书签7" })

keymap.set("n", "<leader>h8", function()
    require("harpoon.ui").nav_file(8)
end, { desc = "打开书签8" })

keymap.set("n", "<leader>h9", function()
    require("harpoon.ui").nav_file(9)
end, { desc = "打开书签9" })

-- LSP -------------------------------------------------------------------------
keymap.set("n", "lh", "<cmd>lua vim.lsp.buf.hover()<CR>", { desc = "显示悬停信息" })
keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "跳转到定义" })
keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { desc = "跳转到声明" })
keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { desc = "跳转到实现" })
keymap.set("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { desc = "跳转到类型定义" })
-- 不使用nvim原生lsp的references，使用telescope的lsp_references
-- keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { desc = "查找引用" })
keymap.set("n", "gr", "<cmd>lua require('telescope.builtin').lsp_references() <CR>", { desc = "查找引用" })
keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { desc = "显示签名帮助" })
keymap.set("n", "rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "重命名符号" })
keymap.set("n", "gf", "<cmd>lua vim.lsp.buf.format({async = true})<CR>", { desc = "格式化代码" })
keymap.set("v", "gf", "<cmd>lua vim.lsp.buf.format({async = true})<CR>", { desc = "格式化选中的代码" })
keymap.set("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", { desc = "显示代码操作" })
-- 使用telescope的的诊断
-- keymap.set("n", "<leader>gl", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "打开诊断浮动窗口" })
keymap.set("n", "gp", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { desc = "跳转到上一个诊断" })
keymap.set("n", "ge", "<cmd>lua vim.diagnostic.goto_next()<CR>", { desc = "跳转到下一个诊断" })
-- 使用telescope的文档符号
-- keymap.set("n", "<leader>tr", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", { desc = "显示文档符号" })
-- keymap.set(
--     "n",
--     "<leader>tr",
--     "<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>",
--     { desc = "显示文档符号" }
-- )

-- 调试（DAP）-----------------------------------------------------------------
-- 通用调试键统一收在 <leader>d* 这一个命名空间下（单一事实来源）。
-- 语言专属的调试入口放各自 ftplugin（如 Python/Java 的「调试测试类/方法」<leader>dt*）。
-- 命名遵循「功能英文首字母 + 大写为反向/更强变体」：
--   b 断点 toggle / B 条件断点 / C 清空全部断点
--   c 继续 / o 跳过(over) / O 跳出(out) / i 步入(into)
--   r REPL / l 运行上次(last) / u 切换 UI / x 终止
-- dap 在打开 python(dap-python) 或 java(jdtls 依赖) 文件时按需加载，故这里用 require 懒包裹。
local function dap()
    return require("dap")
end

keymap.set("n", "<leader>db", function() dap().toggle_breakpoint() end, { desc = "调试: 切换断点" })
keymap.set("n", "<leader>dB", function() dap().set_breakpoint(vim.fn.input("断点条件: ")) end, { desc = "调试: 条件断点" })
keymap.set("n", "<leader>dC", function() dap().clear_breakpoints() end, { desc = "调试: 清空所有断点" })
keymap.set("n", "<leader>dc", function() dap().continue() end, { desc = "调试: 启动/继续" })
keymap.set("n", "<leader>do", function() dap().step_over() end, { desc = "调试: 单步跳过" })
keymap.set("n", "<leader>dO", function() dap().step_out() end, { desc = "调试: 单步跳出" })
keymap.set("n", "<leader>di", function() dap().step_into() end, { desc = "调试: 单步进入" })
keymap.set("n", "<leader>dr", function() dap().repl.toggle() end, { desc = "调试: 切换 REPL" })
keymap.set("n", "<leader>dl", function() dap().run_last() end, { desc = "调试: 运行上次" })
keymap.set("n", "<leader>dx", function() dap().terminate() end, { desc = "调试: 终止" })
keymap.set("n", "<leader>du", function()
    -- dapui.toggle 偶发 Invalid buffer id，pcall 兜底并重试 open（patch 见 plugins/dapui-patch.lua）。
    local ok, err = pcall(function() require("dapui").toggle() end)
    if not ok then
        vim.notify("无法切换调试界面: " .. tostring(err), vim.log.levels.WARN)
        vim.defer_fn(function() pcall(function() require("dapui").open() end) end, 100)
    end
end, { desc = "调试: 切换 UI" })

-- 智能调试启动 ----------------------------------------------------------------
keymap.set("n", "<leader>dd", function()
    -- 获取当前文件路径和类型
    local file_path = vim.fn.expand("%:p")
    local file_type = vim.bo.filetype
    
    -- 使用 pcall 包装所有 DAP 相关调用，避免错误传播
    local status, err = pcall(function()
        -- 如果不是 Python 文件，尝试使用标准 dap 调试
        if file_type ~= "python" then
            -- 如果有可用的调试配置，使用它
            if #require("dap").configurations[file_type] > 0 then
                require("dap").continue()
                vim.defer_fn(function()
                    if package.loaded["dapui"] then
                        local ok = pcall(require("dapui").open)
                        if not ok then
                            vim.notify("无法打开 DAP UI，请重新尝试", vim.log.levels.WARN)
                        end
                    end
                end, 100)
                return
            else
                vim.notify("没有可用的调试配置", vim.log.levels.WARN)
                return
            end
        end
        
        -- Python 文件特殊处理
        -- 读取文件内容
        local file = io.open(file_path, "r")
        if not file then
            vim.notify("无法读取文件内容", vim.log.levels.ERROR)
            return
        end
        
        local content = file:read("*all")
        file:close()
        
        -- 获取当前激活的 Python 解释器
        local python_path = vim.env.VIRTUAL_ENV 
            and vim.fn.expand(vim.env.VIRTUAL_ENV .. "/bin/python")
            or "python"
        
        -- 配置环境变量
        local env = {
            PYTHONPATH = vim.fn.getcwd() .. ":" .. (vim.env.PYTHONPATH or ""),
        }
        
        -- 检测应用类型
        local config = {
            type = "python",
            request = "launch",
            name = "Python: Current File",
            program = file_path,
            python = python_path,
            cwd = vim.fn.getcwd(),
            env = env,
            justMyCode = false,
            console = "integratedTerminal",
        }
        
        -- 检查是否是 Flask 应用
        if content:match("from%s+flask%s+import") or content:match("import%s+flask") then
            config.name = "Flask"
            config.env.FLASK_APP = file_path
            config.env.FLASK_ENV = "development"
            config.env.FLASK_DEBUG = "1"
        -- 检查是否是 FastAPI 应用
        elseif content:match("from%s+fastapi%s+import") or content:match("import%s+fastapi") then
            config.name = "FastAPI"
            config.module = "uvicorn"
            config.args = { 
                vim.fn.fnamemodify(file_path, ":r"):gsub("/", ".") .. ":app", 
                "--reload", 
                "--host", "0.0.0.0", 
                "--port", "8000" 
            }
            config.program = nil -- 使用模块时不需要 program
        end
        
        -- 启动调试前确保存在断点，否则程序会立即执行完毕
        local breakpoints = require("dap.breakpoints").get()
        local has_breakpoints = false
        for _, bps in pairs(breakpoints) do
            if #bps > 0 then
                has_breakpoints = true
                break
            end
        end
        
        if not has_breakpoints then
            -- 提示用户设置断点
            local answer = vim.fn.confirm("没有断点设置，程序可能会立即执行完毕。是否继续？\n提示：按 <leader>db 设置断点", "&是\n&否", 2)
            if answer ~= 1 then
                return
            end
        end
        
        -- 启动调试
        require("dap").run(config)
        
        -- 确保 UI 打开
        vim.defer_fn(function()
            local ui_status, ui_err = pcall(function()
                if package.loaded["dapui"] then
                    require("dapui").open()
                end
            end)
            if not ui_status then
                vim.notify("DAP UI 打开失败: " .. tostring(ui_err), vim.log.levels.WARN)
                -- 尝试再次打开
                vim.defer_fn(function()
                    pcall(function() require("dapui").open() end)
                end, 200)
            end
        end, 100)
    end)
    
    if not status then
        vim.notify("调试启动失败: " .. tostring(err), vim.log.levels.ERROR)
    end
end, { desc = "调试: 调试当前文件" })

-- 仅运行 ----------------------------------------------------------------------
keymap.set("n", "<leader>rp", function()
    local file_path = vim.fn.expand("%:p")
    local file_type = vim.bo.filetype
    
    if file_type ~= "python" then
        vim.notify("当前文件不是 Python 文件", vim.log.levels.ERROR)
        return
    end
    
    local terminal = require("nvterm.terminal")
    local cmd = string.format("python %s", file_path)
    terminal.send(cmd, "float")
end, { desc = "运行当前 Python 文件" })

-- nvterm ----------------------------------------------------------------------
keymap.set({ "t", "n" }, "<A-i>", function()
    require("nvterm.terminal").toggle("float")
end, { desc = "Toggle悬浮终端" })
keymap.set({ "t", "n" }, "<A-h>", function()
    require("nvterm.terminal").toggle("horizontal")
end, { desc = "Toggle水平终端" })
keymap.set({ "t", "n" }, "<A-v>", function()
    require("nvterm.terminal").toggle("vertical")
end, { desc = "Toggle垂直终端" })
-- 宏 --------------------------------------------------------------------------
-- q 还给原生宏录制（q{寄存器} 开始/结束录制），不再占作他用。
-- 重放：@{寄存器} 执行一次，@@ 重复上次。原生键已够短，无需再加映射。

-- hop -------------------------------------------------------------------------
-- 全局跨行跳转用无 leader 单键 s/S（够短、高频）；带范围限定的跳转归到 <leader>F* 跳转区。
keymap.set("n", "S", ":HopChar2<cr>", { desc = "两字符跳转" })
keymap.set("n", "s", ":HopChar1<cr>", { desc = "单字符跳转" })
keymap.set("n", "<leader>Fb", ":HopLineStart<cr>", { desc = "跳转: 行首" })
keymap.set("n", "<leader>Fl", ":HopVertical<cr>", { desc = "跳转: 垂直(行)" })
keymap.set("n", "<leader>Fw", ":HopWord<cr>", { desc = "跳转: 单词" })
-- f/F 增强为「行内单字符跳转」（hop），覆盖原生行内 find，方向：f 向前 / F 向后。
keymap.set({ "n", "v" }, "f", function()
    vim.cmd("HopChar1CurrentLineAC")
end, { desc = "行内单字符向前跳转" })
keymap.set({ "n", "v" }, "F", function()
    vim.cmd("HopChar1CurrentLineBC")
end, { desc = "行内单字符向后跳转" })
-- 注：t/T 不再映射成与 f/F 完全相同的 hop（旧配置如此，纯属浪费两个键），
-- 还给原生 till（dt(/ct" 之类的 operator 组合依赖它）。

-- 全角标点无缝匹配 ------------------------------------------------------------
-- 上面把 n/v 的 f/F/t/T 给了 hop(行内高亮跳转);下面这行只增强 operator-pending 模式
-- 的 f/F/t/T——让 df, / cf。 / dt( 之类的半角键同时命中注释里的全角标点。两者作用在
-- 不同模式,互不影响。逻辑与全/半角对应表收敛在 core/cjk_punct.lua。
require("core.cjk_punct").setup()

-- copilot-chat ----------------------------------------------------------------
-- CopilotChat 插件已停用（见 disable_plugins/），相关快捷键随之移除。

-- 缓冲区 ----------------------------------------------------------------------
-- stylua: ignore start
local utils = require("core.utils")

keymap.set("n", "<leader>bx", function() utils.delete_buffer() end, { desc = "删除缓冲区" })
keymap.set("n", "L", ":bnext<cr>", { desc = "下一个缓冲区" })
keymap.set("n", "H", ":bprevious<cr>", { desc = "上一个缓冲区" })

-- 标签页管理 ------------------------------------------------------------------
keymap.set("n", "<leader>tn", ":tabnew<CR>", { desc = "打开新标签页" }) -- 打开新标签页
keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "关闭标签页" }) -- 关闭标签页
keymap.set("n", "<M-.>", ":tabn<CR>", { desc = "下一个标签页" }) -- 下一个标签页
keymap.set("n", "<M-,>", ":tabp<CR>", { desc = "上一个标签页" }) -- 上一个标签页

-- Minifiles -------------------------------------------------------------------
vim.api.nvim_set_keymap("n", "<leader>ef", ":lua RevealInMiniFiles()<CR>",
  { noremap = true, silent = true, desc = "在MiniFiles中显示" })

function RevealInMiniFiles()
  local path = vim.fn.expand("%:p:h") -- 获取当前文件的目录路径
  require("mini.files").open(path)    -- 在 mini.files 中打开该目录
end

-- 调试：DAP UI widgets --------------------------------------------------------
-- 上面「调试」段未覆盖的补充键。
keymap.set("n", "<leader>dh", function() require("dap.ui.widgets").hover() end, { desc = "调试: 悬停显示" })
keymap.set("n", "<leader>d?", function() require("dap.ui.widgets").preview() end, { desc = "调试: 预览" })

-- 重构：基于原生 LSP ----------------------------------------------------------
-- refactoring.nvim 插件已停用，提取方法/变量/内联三项随之移除。
-- 重命名走无 leader 的 rn（见上方 LSP 段，单一事实来源）；这里不再重复绑 <leader>re。
keymap.set("n", "<leader>mv", function() vim.lsp.buf.code_action({ context = { only = { "refactor.move" } } }) end, { desc = "重构: 移动" })
