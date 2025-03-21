return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "echasnovski/mini.icons", "scottmckendry/cyberdream.nvim" },
    opts = function()
        local utils = require("core.utils")
        -- 为copilot状态设置颜色
        local copilot_colors = {
            [""] = utils.get_hlgroup("Comment"),
            ["Normal"] = utils.get_hlgroup("Comment"),
            ["Warning"] = utils.get_hlgroup("DiagnosticError"),
            ["InProgress"] = utils.get_hlgroup("DiagnosticWarn"),
        }

        -- 为不同的文件类型设置图标
        local filetype_map = {
            lazy = { name = "lazy.nvim", icon = "💤" },
            minifiles = { name = "minifiles", icon = "🗂️ " },
            toggleterm = { name = "terminal", icon = "🐚" },
            mason = { name = "mason", icon = "🔨" },
            TelescopePrompt = { name = "telescope", icon = "🔍" },
            ["copilot-chat"] = { name = "copilot", icon = "🤖" },
        }

        return {
            options = {
                -- 组件分割符为空格
                component_separators = { left = " ", right = " " },
                -- 区域分割符为空格
                section_separators = { left = " ", right = " " },
                -- 自动选择主题
                theme = "auto",
                -- 启用全局状态栏
                globalstatus = true,
                -- 禁用的文件类型
                disabled_filetypes = { statusline = { "dashboard", "alpha" } },
            },
            -- 设置区域
            sections = {
                -- a区域 小写格式自定义图标
                lualine_a = {
                    {
                        "mode",
                        icon = "",
                        fmt = function(mode)
                            return mode:lower()
                        end,
                    },
                },
                -- b区域 git 分支图标
                lualine_b = { { "branch", icon = "" } },
                -- c区域
                lualine_c = {
                    -- 诊断图标
                    {
                        "diagnostics",
                        symbols = {
                            error = " ",
                            warn = " ",
                            info = " ",
                            hint = "󰝶 ",
                        },
                    },
                    -- 优先显示filetype_map配置的图标，否则显示文件类型默认图标
                    {
                        function()
                            local devicons = require("nvim-web-devicons")
                            local ft = vim.bo.filetype
                            local icon
                            if filetype_map[ft] then
                                return " " .. filetype_map[ft].icon
                            end
                            if icon == nil then
                                icon = devicons.get_icon(vim.fn.expand("%:t"))
                            end
                            if icon == nil then
                                icon = devicons.get_icon_by_filetype(ft)
                            end
                            if icon == nil then
                                icon = " 󰈤"
                            end

                            return icon .. " "
                        end,
                        color = function()
                            local _, hl = require("nvim-web-devicons").get_icon(vim.fn.expand("%:t"))
                            if hl then
                                return hl
                            end
                            return utils.get_hlgroup("Normal")
                        end,
                        separator = "",
                        padding = { left = 0, right = 0 },
                    },
                    -- 显示文filetype_map中配置的文件类型名
                    {
                        "filename",
                        padding = { left = 0, right = 0 },
                        fmt = function(name)
                            if filetype_map[vim.bo.filetype] then
                                return filetype_map[vim.bo.filetype].name
                            else
                                return name
                            end
                        end,
                    },
                    -- 显示缓冲区数量 大于1则显示
                    {
                        function()
                            local buffer_count = require("core.utils").get_buffer_count()

                            return "+" .. buffer_count - 1 .. " "
                        end,
                        cond = function()
                            return require("core.utils").get_buffer_count() > 1
                        end,
                        color = utils.get_hlgroup("Operator", nil),
                        padding = { left = 0, right = 1 },
                    },
                    {
                        function()
                            local tab_count = vim.fn.tabpagenr("$")
                            if tab_count > 1 then
                                return vim.fn.tabpagenr() .. " of " .. tab_count
                            end
                        end,
                        cond = function()
                            return vim.fn.tabpagenr("$") > 1
                        end,
                        icon = "󰓩",
                        color = utils.get_hlgroup("Special", nil),
                    },
                    -- 显示当前所在代码片段位置
                    {
                        function()
                            return require("nvim-navic").get_location()
                        end,
                        cond = function()
                            return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
                        end,
                        color = utils.get_hlgroup("Comment", nil),
                    },
                },
                lualine_x = {
                    {
                        -- 显示更新状态
                        require("lazy.status").updates,
                        cond = require("lazy.status").has_updates,
                        color = utils.get_hlgroup("String"),
                    },
                    -- 显示copilot状态
                    {
                        function()
                            local icon = " "
                            local status = require("copilot.api").status.data
                            return icon .. (status.message or "")
                        end,
                        cond = function()
                            local ok, clients = pcall(vim.lsp.get_clients, { name = "copilot", bufnr = 0 })
                            return ok and #clients > 0
                        end,
                        color = function()
                            if not package.loaded["copilot"] then
                                return
                            end
                            local status = require("copilot.api").status.data
                            return copilot_colors[status.status] or copilot_colors[""]
                        end,
                    },
                    -- 显示Git差异
                    { "diff" },
                },
                -- 显示文件进度和光标位置
                lualine_y = {
                    {
                        "progress",
                    },
                    {
                        "location",
                        color = utils.get_hlgroup("Boolean"),
                    },
                },
                -- 显示时间
                lualine_z = {
                    {
                        "datetime",
                        style = "  %Y-%m-%d %X",
                    },
                },
            },
        }
    end,
}
