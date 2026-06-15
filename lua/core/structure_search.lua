-- 类 PyCharm 结构搜索:树形观感 + 实时模糊过滤的符号 picker
--
-- 为什么自己写:telescope 自带的 aerial 扩展把符号拍平成只有叶子名的一维列表
-- (format_symbol 默认只取 symbol_path 末项),既看不出 class→method 的归属,
-- 也没有缩进。aerial 浮窗(<leader>fs)有树缩进却要先按 / 才能搜。这里取两者
-- 之长:直接读 aerial 的符号数据(item 自带 level 深度与 parent 链),做到——
--
--   · 空输入:按文件顺序、用 level 缩进 + guide 线展示,观感即一棵树;
--   · 打字时:ordinal 里塞完整路径 Foo.method,既能搜叶子名也能搜带类名,
--     telescope 按匹配度重排(此刻缩进失去意义,但路径文字仍标明归属)。
--
-- 物理硬限制:telescope 一旦 fuzzy 过滤就按匹配度重排条目,所以「边搜边保持
-- 可折叠的树结构」做不到——那是 telescope 模型本身的取舍,只有浮窗才有。
-- 本 picker 是该框架下「树形观感 + 实时搜索」能达到的最好状态。

local M = {}

function M.open()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local entry_display = require("telescope.pickers.entry_display")

    -- 触发 aerial 懒加载并确保当前 buffer 已有符号数据
    require("aerial").sync_load()
    local backends = require("aerial.backends")
    local data = require("aerial.data")
    local aerial_config = require("aerial.config")
    local highlight = require("aerial.highlight")

    local bufnr = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(0)

    local backend = backends.get()
    if not backend then
        backends.log_support_err()
        return
    end
    if not data.has_symbols(0) then
        backend.fetch_symbols_sync(0, {})
    end
    if not data.has_symbols(0) then
        vim.notify("当前文件没有可用的符号大纲", vim.log.levels.INFO)
        return
    end

    -- guide 字符:取自 aerial 配置,保证缩进观感和浮窗大纲一致
    local guides = aerial_config.guides
        or { mid_item = "├─", last_item = "└─", nested_top = "│ ", whitespace = "  " }

    -- 收集符号:按文件出现顺序(iter 默认顺序),保留 level 做缩进、parent 拼路径
    local results = {}
    local bufdata = data.get_or_create(0)
    for _, item in bufdata:iter({ skip_hidden = false }) do
        table.insert(results, item)
    end

    -- 列布局:guide 缩进 + 图标 + 符号名(三段),宽度交给 telescope 自适应
    local displayer = entry_display.create({
        separator = "",
        items = {
            { remaining = true },
        },
    })

    -- 拼完整路径 Foo.method,供搜索用(ordinal),也作 fallback 显示
    local function full_path(item)
        local parts = {}
        local cur = item
        while cur do
            table.insert(parts, 1, cur.name)
            cur = cur.parent
        end
        return table.concat(parts, ".")
    end

    local function make_display(entry)
        local item = entry.value
        local icon = aerial_config.get_icon(bufnr, item.kind)
        local icon_hl = highlight.get_highlight(item, true, false) or "NONE"
        local name_hl = highlight.get_highlight(item, false, false) or "NONE"
        -- 按 level 生成缩进:每层两格,贴近浮窗的树观感
        local indent = string.rep(guides.whitespace, item.level)
        local prefix = indent .. icon .. " "
        return displayer({
            { prefix .. item.name, name_hl },
        }),
            -- 给图标单独上 kind 色:图标紧跟在 indent 之后
            { { { #indent, #indent + #icon }, icon_hl } }
    end

    local function make_entry(item)
        local path = full_path(item)
        local lnum = item.selection_range and item.selection_range.lnum or item.lnum
        local col = item.selection_range and item.selection_range.col or item.col
        return {
            value = item,
            display = make_display,
            -- ordinal 用完整路径:既能搜叶子名 method,也能搜带类名 Foo.method
            ordinal = path .. " " .. string.lower(item.kind),
            name = path,
            lnum = lnum,
            col = (col or 0) + 1,
            filename = filename,
        }
    end

    pickers
        .new({}, {
            prompt_title = "结构搜索",
            finder = finders.new_table({
                results = results,
                entry_maker = make_entry,
            }),
            sorter = conf.generic_sorter({}),
            previewer = conf.qflist_previewer({}),
            push_cursor_on_edit = true,
            -- telescope 默认 sorting_strategy = "descending":第一条结果贴着输入框
            -- 放在底部,会把这里的树形顺序整个上下颠倒,与 <leader>fS 浮窗(普通
            -- buffer,从上往下渲染)相反。改成升序 + 输入框置顶,让符号从上到下排,
            -- 与浮窗大纲保持一致的阅读顺序。
            sorting_strategy = "ascending",
            layout_config = { prompt_position = "top" },
        })
        :find()
end

return M
