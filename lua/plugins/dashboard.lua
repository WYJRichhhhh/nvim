-- 设置打开nvim时首页
return {
    "nvimdev/dashboard-nvim",
    -- 在进入 vim 时，触发 Dashboard 插件
    event = "VimEnter",
    dev = true,
    config = function()
        -- 设置前景色为白色
        vim.cmd("highlight DashboardHeader guifg=#ffffff")
        require("dashboard").setup({
            theme = "hyper",
            -- 不隐藏状态栏
            hide = {
                statusline = false,
            },
            config = {
                -- 显示当前周几
                week_header = { enable = true },
                shortcut = {
                    -- 按u更新 lazy
                    {
                        icon = "󰒲  ",
                        icon_hl = "Boolean",
                        desc = "Update ",
                        group = "Directory",
                        action = "Lazy update",
                        key = "u",
                    },
                    -- 按f查找文件
                    {
                        icon = "   ",
                        icon_hl = "Boolean",
                        desc = "Files ",
                        group = "Statement",
                        action = "Telescope find_files",
                        key = "f",
                    },
                    -- 按r查找最近打开的文件
                    {
                        icon = "   ",
                        icon_hl = "Boolean",
                        desc = "Recent ",
                        group = "String",
                        action = "Telescope oldfiles",
                        key = "r",
                    },
                    -- 按g查找字符串
                    {
                        icon = "   ",
                        icon_hl = "Boolean",
                        desc = "Grep ",
                        group = "ErrorMsg",
                        action = "Telescope live_grep",
                        key = "g",
                    },
                    -- 按q退出
                    {
                        icon = "   ",
                        icon_hl = "Boolean",
                        desc = "Quit ",
                        group = "WarningMsg",
                        action = "qall!",
                        key = "q",
                    },
                },
                project = { enable = false },
                mru = { enable = false },
                footer = {},
            },
        })
    end,
}
