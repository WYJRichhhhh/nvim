-- 代码补全
return {
    "saghen/blink.cmp",
    dev = true,
    lazy = false,
    dependencies = "rafamadriz/friendly-snippets",
    version = "v0.*",
    -- build = "cargo build --release",
    config = function()
        require("blink.cmp").setup({
            keymap = {
                preset = "enter",
            },

            windows = {
                autocomplete = {
                    draw = "reversed",
                    border = {
                        { "󱐋", "WarningMsg" },
                        "─",
                        "╮",
                        "│",
                        "╯",
                        "─",
                        "╰",
                        "│",
                    },
                },
                documentation = {
                    auto_show = true,
                    border = {
                        { "", "DiagnosticHint" },
                        "─",
                        "╮",
                        "│",
                        "╯",
                        "─",
                        "╰",
                        "│",
                    },
                },
                signature_help = { border = "rounded" },
            },
        })
    end,
}
