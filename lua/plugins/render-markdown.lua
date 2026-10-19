return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    config = function()
        require("render-markdown").setup({
            pipe_table = {
                border = { "╭", "┬", "╮", "├", "┼", "┤", "╰", "┴", "╯", "│", "─" },
            },
            code = {
                -- Mermaid 交给 Snacks 图像层，避免两边同时 conceal 同一代码块。
                disable = { "mermaid" },
                width = "block",
                left_pad = 2,
                right_pad = 2,
            },
        })
    end,
}
