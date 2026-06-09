return {
    "smiteshp/nvim-navic",
    config = function()
        require("nvim-navic").setup({
            lsp = {
                auto_attach = true,
                -- 向当前 buffer 挂载 LSP 时的优先级顺序
                preference = {
                    "html",
                    "templ",
                },
            },
            separator = " 󰁔 ",
        })
    end,
}
