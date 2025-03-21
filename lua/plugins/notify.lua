return {
    "rcarriga/nvim-notify",
    config = function()
        require("notify").setup({
            max_height = 10,
            max_width = 50,
            background_colour = "NotifyBackground",
            fps = 30,
            icons = {
                DEBUG = "",
                ERROR = "",
                INFO = "",
                TRACE = "✎",
                WARN = "",
            },
            level = 2,
            minimum_width = 50,
            render = "default",
            stages = "fade_in_slide_out",
            time_formats = {
                notification = "%T",
                notification_history = "%FT%T",
            },
            timeout = 2000,
            top_down = true,
            on_open = function() end,
            on_close = function() end,
        })

        -- Keymap
        local map = vim.keymap.set

        map("n", "<leader>nd", function()
            require("notify").dismiss({ silent = true, pending = true })
        end, { desc = "忽视所有通知" })

        map("n", "<leader>na", "<cmd>Notifications<cr>", { desc = "展示所有通知" })
    end,
}
