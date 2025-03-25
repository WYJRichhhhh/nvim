return {
    "rcarriga/nvim-notify",
    config = function()
        local notify = require("notify")
        notify.setup({
            max_height = 10,
            max_width = 50,
            background_colour = "NotifyBackground",
            fps = 30,
            icons = {
                DEBUG = "",
                ERROR = "",
                INFO = "",
                TRACE = "✎",
                WARN = "",
            },
            level = 1,
            minimum_width = 50,
            render = "default",
            stages = "fade_in_slide_out",
            time_formats = {
                notification = "%T",
                notification_history = "%FT%T",
            },
            timeout = 2000,
            top_down = true,
            on_open = function(win)
                -- 为通知窗口添加q键映射以关闭窗口
                local buf = vim.api.nvim_win_get_buf(win)
                vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
            end,
            on_close = function() end,
            max_history = 100,
        })

        vim.notify = notify

        local map = vim.keymap.set

        map("n", "<leader>nd", function()
            notify.dismiss({ silent = true, pending = true })
        end, { desc = "忽视所有通知" })

        map("n", "<leader>na", "<cmd>Notifications<cr>", { desc = "展示所有通知" })

        map("n", "<leader>nh", function()
            require("telescope").extensions.notify.notify()
        end, { desc = "查看通知历史" })
    end,
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
}
