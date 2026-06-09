-- 代码符号大纲(树状)
--
-- 为什么引入:telescope 的 lsp_document_symbols 本质是个一维模糊列表,
-- 给不出 class → method 的父子层级。aerial 专做大纲,能按 LSP/treesitter
-- 的符号树缩进折叠展示,并跟随光标高亮当前所在符号。键位在 core/keymaps.lua
-- 里(<leader>fs),与其它查找类键位聚合在一处。
return {
    -- https://github.com/stevearc/aerial.nvim
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
    dependencies = {
        -- 符号取自 treesitter,LSP 未就绪时也能出大纲
        "nvim-treesitter/nvim-treesitter",
        -- 图标统一走 mini.icons(它已 mock nvim-web-devicons),不再单独引入
        "echasnovski/mini.icons",
    },
    opts = {
        -- 符号来源优先级:有 LSP 用 LSP,否则退回 treesitter,保证总有结果
        backends = { "lsp", "treesitter", "markdown", "man" },
        layout = {
            default_direction = "right",
            min_width = 30,
        },
        -- 打开大纲后自动把光标跳进去,方便直接 j/k 浏览
        attach_mode = "global",
        -- 跟随光标:始终高亮当前符号,并自动展开其所在层级
        highlight_on_hover = true,
        show_guides = true,
        -- 过滤掉噪音符号,只保留有结构意义的那几类,大纲更干净
        filter_kind = {
            "Class",
            "Constructor",
            "Enum",
            "Function",
            "Interface",
            "Module",
            "Method",
            "Struct",
        },
    },
}
