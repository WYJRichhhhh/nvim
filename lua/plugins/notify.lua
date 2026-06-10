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

        -- 不在这里抢 vim.notify。vim.notify 的归属统一交给 noice(见 plugins/noice.lua
        -- 的 notify.enabled=true):noice 负责路由所有通知,再转发给 nvim-notify 做实际
        -- 渲染。本文件只配置 nvim-notify 的外观与历史——它仍是后端渲染器 + 历史来源,
        -- 所以 telescope notify(<leader>nh)照常工作。曾经这里有一行 `vim.notify = notify`
        -- 把归属抢回 nvim-notify,与 noice 形成「谁后加载谁生效」的二义性(实测 noice 走
        -- VeryLazy 后加载、本就胜出,那行是被覆盖的死代码),已删除以保证单一事实来源。
        local map = vim.keymap.set

        map("n", "<leader>nd", function()
            notify.dismiss({ silent = true, pending = true })
        end, { desc = "忽视所有通知" })

        map("n", "<leader>na", "<cmd>Notifications<cr>", { desc = "展示所有通知" })

        -- telescope 模糊搜通知历史的键(原 <leader>nh)已挪到 core/keymaps.lua 的
        -- Telescope 段、改绑 <leader>fn:它本质是「在通知域里模糊查找」,跟 fb/fd/fh/ft
        -- 同属 f+域首字母 的查找系列,集中在一处更一致。本文件只留 nvim-notify 自身
        -- 专属的键(dismiss/Notifications)。
    end,
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
}
