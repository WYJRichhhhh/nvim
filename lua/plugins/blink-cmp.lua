-- 稳定版接口与预编译匹配器配套，避免跟随 main 的不兼容变化。
return {
    "saghen/blink.cmp",
    version = "1.*",
    lazy = false,
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
        keymap = {
            preset = "enter",
            ["<C-j>"] = { "select_next", "fallback" },
            ["<C-k>"] = { "select_prev", "fallback" },
            ["<C-d>"] = { "scroll_documentation_up", "fallback" },
            ["<C-f>"] = { "scroll_documentation_down", "fallback" },
            ["<CR>"] = { "select_and_accept", "fallback" },
            ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        },
        completion = {
            list = { selection = { preselect = true, auto_insert = false } },
            menu = { border = "rounded" },
            documentation = { auto_show = true, window = { border = "rounded" } },
            -- 括号仍交给 nvim-autopairs，避免两套逻辑重复插入。
            accept = { auto_brackets = { enabled = false } },
        },
        sources = { default = { "lsp", "path", "snippets", "buffer" } },
        -- 无可用 Rust 二进制时退回 Lua，跨机器使用无需安装编译工具链。
        fuzzy = { implementation = "prefer_rust" },
        cmdline = { enabled = true },
    },
}
