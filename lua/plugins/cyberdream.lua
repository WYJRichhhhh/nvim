-- 主题插件
return {
    {
        "scottmckendry/cyberdream.nvim",
        dev = true,
        lazy = false,
        priority = 1000,
        config = function()
            require("cyberdream").setup({
                transparent = true, -- 透明
                italic_comments = true, -- 斜体注释
                hide_fillchars = true, -- 隐藏fillchars ,比如md中的#
                terminal_colors = false, -- 终端颜色
                cache = false, -- 缓存
                borderless_telescope = { border = false, style = "flat" }, -- 无边框的telescope
                theme = { variant = "light" }, -- 主题
                extensions = { telescope = true }, -- 扩展
            })

            vim.cmd("colorscheme cyberdream-light") -- 设置vim主题
            vim.api.nvim_set_keymap("n", "<leader>tt", ":CyberdreamToggleMode<CR>", { noremap = true, silent = true })
        end,
    },
}
