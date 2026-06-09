return {
    "folke/noice.nvim",
    event = "VeryLazy",
    config = function()
        require("noice").setup({
            cmdline = {
                enabled = true, -- 启用 Noice 的 cmdline UI
                view = "cmdline_popup", -- 渲染 cmdline 的视图。改成 `cmdline` 可回到底部的经典命令行
                opts = {}, -- cmdline 的全局选项，详见 views 一节
                format = {
                    -- conceal:（默认 true）隐藏 cmdline 中匹配该 pattern 的文本
                    -- view:（默认是 cmdline 视图）
                    -- opts: 传给视图的任意选项
                    -- icon_hl_group: 图标可选的 hl_group
                    -- title: 设为任意值或空字符串即可隐藏
                    cmdline = { pattern = "^:", icon = "", lang = "vim" },
                    search_down = { kind = "search", pattern = "^/", icon = "󰱼 ", lang = "regex" },
                    search_up = { kind = "search", pattern = "^%?", icon = "󰱼 ", lang = "regex" },
                    filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
                    lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
                    help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
                    input = {}, -- 供 input() 使用
                    -- lua = false, -- to disable a format, set to `false`
                },
            },
            messages = {
                -- 注意：启用 messages 后 cmdline 会被自动启用，
                -- 这是当前 Neovim 的限制。
                enabled = true, -- 启用 Noice 的 messages UI
                view = "notify", -- 消息的默认视图
                view_error = "notify", -- 错误的视图
                view_warn = "notify", -- 警告的视图
                view_history = "messages", -- :messages 的视图
                view_search = "virtualtext", -- 搜索计数消息的视图。设为 `false` 可禁用
            },
            popupmenu = {
                enabled = true, -- 启用 Noice 的 popupmenu UI
                backend = "nui", -- 显示常规 cmdline 补全所用的后端
                -- 补全项类型的图标（默认值见 noice.config.icons.kinds）
                kind_icons = {}, -- 设为 `false` 可禁用图标
            },
            -- require('noice').redirect 的默认选项
            -- 详见 Command Redirection 一节
            redirect = {
                view = "popup",
                filter = { event = "msg_show" },
            },
            -- 下面可添加任意自定义命令，通过 `:Noice command` 调用
            commands = {
                history = {
                    -- `:Noice` 打开的消息历史的选项
                    view = "split",
                    opts = { enter = true, format = "details" },
                    filter = {
                        any = {
                            { event = "notify" },
                            { error = true },
                            { warning = true },
                            { info = true },
                            { event = "msg_show", kind = { "" } },
                            { event = "lsp", kind = "message" },
                        },
                    },
                },
                -- :Noice last
                last = {
                    view = "popup",
                    opts = { enter = true, format = "details" },
                    filter = {
                        any = {
                            { event = "notify" },
                            { error = true },
                            { warning = true },
                            { info = true },
                            { event = "msg_show", kind = { "" } },
                            { event = "lsp", kind = "message" },
                        },
                    },
                    filter_opts = { count = 1 },
                },
                -- :Noice errors
                errors = {
                    -- `:Noice` 打开的消息历史的选项
                    view = "popup",
                    opts = { enter = true, format = "details" },
                    filter = { error = true },
                    filter_opts = { reverse = true },
                },
                -- 添加新命令用于查看信息级别的消息
                info = {
                    view = "popup",
                    opts = { enter = true, format = "details" },
                    filter = { info = true },
                    filter_opts = { reverse = true },
                },
            },
            notify = {
                -- Noice 可以充当 `vim.notify`，从而像其它消息一样路由任意通知。
                -- 通知消息会带有 level 等属性，event 恒为 "notify"，
                -- kind 可以是任意日志等级的字符串。
                -- 默认路由会把通知转发给 nvim-notify。
                -- 用 Noice 接管的好处是路由统一、历史视图一致。
                enabled = true,
                view = "notify",
            },
            lsp = {
                progress = {
                    enabled = false,
                    -- LSP 进度用 lsp_progress 内置 formatter 格式化，详见 config.format.builtin。
                    -- 自定义格式的更多说明见 formatting 一节。
                    format = "lsp_progress",
                    format_done = "lsp_progress_done",
                    throttle = 1000 / 30, -- 更新 LSP 进度消息的频率
                    view = "mini",
                },
                override = {
                    -- 用 Noice 覆盖默认的 LSP markdown formatter
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
                    -- 用 Noice 覆盖 LSP markdown formatter
                    ["vim.lsp.util.stylize_markdown"] = false,
                    -- 用 Noice 覆盖 cmp 文档（需要上面几项一起开启才生效）
                    ["cmp.entry.get_documentation"] = false,
                },
                hover = {
                    enabled = false,
                    silent = false, -- 设为 true 时，hover 不可用也不提示消息
                    view = nil, -- 为 nil 时使用 documentation 的默认值
                    opts = {}, -- 与 documentation 的默认值合并
                },
                signature = {
                    enabled = false,
                    auto_open = {
                        enabled = true,
                        trigger = true, -- 输入 LSP 的触发字符时自动弹出签名帮助
                        luasnip = true, -- 跳到 Luasnip 插入节点时弹出签名帮助
                        throttle = 50, -- LSP 签名帮助请求去抖 50ms
                    },
                    view = nil, -- 为 nil 时使用 documentation 的默认值
                    opts = {}, -- 与 documentation 的默认值合并
                },
                message = {
                    -- LSP 服务器显示的消息
                    enabled = true,
                    view = "notify",
                    opts = {},
                },
                -- hover 和签名帮助的默认值
                documentation = {
                    view = "hover",
                    opts = {
                        lang = "markdown",
                        replace = true,
                        render = "plain",
                        format = { "{message}" },
                        win_options = { concealcursor = "n", conceallevel = 3 },
                    },
                },
            },
            markdown = {
                hover = {
                    ["|(%S-)|"] = vim.cmd.help, -- vim 帮助链接
                    ["%[.-%]%((%S-)%)"] = require("noice.util").open, -- markdown 链接
                },
                highlights = {
                    ["|%S-|"] = "@text.reference",
                    ["@%S+"] = "@parameter",
                    ["^%s*(Parameters:)"] = "@text.title",
                    ["^%s*(Return:)"] = "@text.title",
                    ["^%s*(See also:)"] = "@text.title",
                    ["{%S-}"] = "@parameter",
                },
            },
            health = {
                checker = true, -- 不想跑健康检查就禁用它
            },
            smart_move = {
                -- noice 会尝试避开已有的浮动窗口。
                enabled = true, -- 可在此关闭该行为
                -- 在这里加入不应触发 smart move 的 filetype。
                excluded_filetypes = { "cmp_menu", "cmp_docs", "notify" },
            },
            presets = {
                -- 把某个 preset 设为 true 即可启用，也可设为一个表来覆盖该 preset 的配置；
                -- 还可以添加自定义 preset，通过 enabled=true 来开关。
                bottom_search = false, -- 搜索时使用经典的底部命令行
                command_palette = false, -- 把 cmdline 和 popupmenu 放在一起
                long_message_to_split = false, -- 长消息发送到 split 窗口
                inc_rename = false, -- 为 inc-rename.nvim 启用输入对话框
                lsp_doc_border = false, -- 给 hover 文档和签名帮助加边框
            },
            throttle = 1000 / 30, -- Noice 检查 UI 更新的频率。阻塞模式下此项无效。
            views = {
                -- 配置popup视图
                popup = {
                    -- 设置弹出窗口的选项
                    win_options = {
                        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
                    },
                    -- 为popup视图添加按键映射
                    mappings = {
                        ["q"] = "Close", -- 添加q键关闭窗口
                        ["<Esc>"] = "Close", -- 添加Esc键关闭窗口
                    },
                },
                -- 配置messages视图
                messages = {
                    -- 设置messages视图的按键映射
                    mappings = {
                        ["q"] = "Close", -- 添加q键关闭窗口
                        ["<Esc>"] = "Close", -- 添加Esc键关闭窗口
                    },
                },
                -- 配置split视图
                split = {
                    -- 为split视图添加按键映射
                    mappings = {
                        ["q"] = "Close", -- 添加q键关闭窗口
                        ["<Esc>"] = "Close", -- 添加Esc键关闭窗口
                    },
                },
            },
            routes = {},
            status = {},
            format = {},
        })
        
        -- 添加快捷键查看info级别的消息
        vim.keymap.set("n", "<leader>ni", "<cmd>Noice info<cr>", { desc = "查看信息级别的消息" })
    end,
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },
}
