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

            -- 恢复窗口分隔线 ------------------------------------------------------
            -- hide_fillchars=true 会把 eob(行尾 ~)连同 vert/horiz 等窗口分隔符字符
            -- 一起清成空格(见 cyberdream theme.lua),导致 split 之间完全没有可见边界。
            -- 这里只补回分隔符字符、并给 WinSeparator 一个清晰颜色，eob 仍保持隐藏。
            -- 必须挂在 ColorScheme 上：leader tt 切换亮暗会重跑主题、再次清空 fillchars。
            local function restore_win_separators()
                vim.opt.fillchars:append({
                    vert = "│",
                    horiz = "─",
                    horizup = "┴",
                    horizdown = "┬",
                    vertleft = "┤",
                    vertright = "├",
                    verthoriz = "┼",
                })
                -- 浅灰，亮暗两种变体下都能看清边界
                vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#808080" })
            end
            restore_win_separators()
            vim.api.nvim_create_autocmd("ColorScheme", {
                pattern = "cyberdream*",
                callback = restore_win_separators,
            })
        end,
    },
}
