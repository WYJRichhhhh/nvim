-- Python开发环境配置
return {
    {
        -- Python环境管理
        "linux-cultist/venv-selector.nvim",
        ft = "python",
        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-telescope/telescope.nvim",
            "NvChad/nvterm", -- 添加 nvterm 依赖
        },
        config = function()
            require("venv-selector").setup({
                name = ".venv",
                auto_refresh = true,
                search = true,
                search_venv_managers = true,
                search_workspace = true,
                dap_enabled = true,
                stay_on_this_version = true,
                parents = 0,
                -- 新增配置
                search_dir = function()
                    return vim.fn.getcwd()
                end,
                -- 自动检测并激活虚拟环境
                auto_refresh_on_write = true,
                -- 在状态栏显示当前环境
                status_line = true,
                -- 在切换环境时自动重启LSP和更新终端
                post_set_venv = function()
                    -- 重启所有Python相关的LSP
                    local clients = vim.lsp.get_active_clients()
                    for _, client in ipairs(clients) do
                        if client.name == "pyright" or client.name == "ruff" then
                            -- 先停止LSP
                            client.stop()
                            -- 等待一小段时间确保完全停止
                            vim.defer_fn(function()
                                -- 重新启动LSP
                                vim.cmd("LspStart " .. client.name)
                            end, 100)
                        end
                    end

                    -- 更新所有打开的终端
                    local venv = os.getenv("VIRTUAL_ENV")
                    if venv then
                        local activate_cmd = vim.fn.has("win32") == 1 and venv .. "/Scripts/activate"
                            or "source " .. venv .. "/bin/activate"
                        -- 获取项目根目录
                        local project_root = vim.fn.getcwd()

                        -- 设置PYTHONPATH环境变量
                        local current_pythonpath = os.getenv("PYTHONPATH") or ""
                        -- 确保项目根目录在PYTHONPATH中
                        if not string.find(current_pythonpath, project_root) then
                            if current_pythonpath ~= "" then
                                vim.env.PYTHONPATH = project_root .. ":" .. current_pythonpath
                            else
                                vim.env.PYTHONPATH = project_root
                            end
                        end

                        -- 获取Python版本
                        local python_path = venv .. "/bin/python"
                        local python_version = vim.fn
                            .system(
                                python_path
                                    .. " -c 'import sys; print(f\"{sys.version_info.major}.{sys.version_info.minor}\")'"
                            )
                            :gsub("\n", "")

                        -- 将site-packages添加到PYTHONPATH
                        local site_packages = venv .. "/lib/python" .. python_version .. "/site-packages"
                        if not string.find(vim.env.PYTHONPATH, site_packages) then
                            vim.env.PYTHONPATH = vim.env.PYTHONPATH .. ":" .. site_packages
                        end

                        -- 输出环境变量信息
                        vim.notify(
                            "已更新Python环境:\nVENV: " .. venv .. "\nPYTHONPATH: " .. vim.env.PYTHONPATH,
                            vim.log.levels.INFO
                        )

                        -- 获取所有终端窗口
                        local terminals = require("nvterm").get_all()
                        for _, term in ipairs(terminals) do
                            -- 发送激活命令到终端
                            vim.api.nvim_chan_send(term, activate_cmd .. "\n")
                            -- 设置 PYTHONPATH
                            vim.api.nvim_chan_send(term, string.format("export PYTHONPATH=%s\n", vim.env.PYTHONPATH))
                        end

                        -- 触发环境变化事件 - 这将通过自动命令更新DAP
                        vim.api.nvim_exec_autocmds("User", { pattern = "VenvSelectorVenvChanged" })
                    end
                end,
                -- 搜索路径配置
                search_paths = {
                    "./venv",
                    "./.venv",
                    "./.env",
                    vim.fn.expand("~/.virtualenvs"),
                    vim.fn.expand("~/.pyenv/versions"),
                },
                -- 虚拟环境创建命令
                create_venv = function(path)
                    return string.format("python -m venv %s", path)
                end,
                -- 虚拟环境激活命令
                activate_venv = function(path)
                    if vim.fn.has("win32") == 1 then
                        return path .. "/Scripts/activate"
                    else
                        return "source " .. path .. "/bin/activate"
                    end
                end,
            })

            -- 设置快捷键
            vim.keymap.set("n", "<leader>pe", "<cmd>VenvSelect<cr>", { desc = "选择Python环境" })
            vim.keymap.set("n", "<leader>pc", "<cmd>VenvSelectCached<cr>", { desc = "显示当前Python环境" })
            vim.keymap.set("n", "<leader>pn", "<cmd>VenvSelectCreate<cr>", { desc = "创建新的Python环境" })
        end,
    },
    {
        -- Python代码格式化工具
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        ft = { "python" },
        opts = {
            formatters_by_ft = {
                python = { "black", "isort" },
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true,
            },
        },
    },
    {
        -- 自动导入优化
        "tell-k/vim-autoflake",
        ft = "python",
        config = function()
            vim.g.autoflake_remove_all_unused_imports = 1
            vim.g.autoflake_remove_unused_variables = 1
            -- 设置快捷键来移除未使用的导入
            vim.keymap.set("n", "<leader>oi", ":Autoflake<CR>", { desc = "移除未使用的导入" })
        end,
    },
    {
        -- Python调试
        "mfussenegger/nvim-dap-python",
        ft = "python",
        dependencies = {
            "mfussenegger/nvim-dap",
            "rcarriga/nvim-dap-ui",
            "theHamsta/nvim-dap-virtual-text",
            "nvim-telescope/telescope-dap.nvim",
        },
        config = function()
            -- 自动检测当前活动的Python解释器
            local function get_python_path()
                local venv = os.getenv("VIRTUAL_ENV")
                if venv then
                    return venv .. "/bin/python"
                end
                -- 考虑pyenv环境
                local pyenv_root = os.getenv("PYENV_ROOT")
                if pyenv_root then
                    local pyenv_version = vim.fn.system("pyenv version-name"):gsub("\n", "")
                    local pyenv_python = pyenv_root .. "/versions/" .. pyenv_version .. "/bin/python"
                    if vim.fn.executable(pyenv_python) == 1 then
                        return pyenv_python
                    end
                end
                return "/usr/bin/python3" -- 默认使用系统Python
            end

            -- 设置Python调试器
            local function setup_dap_python(python_path)
                -- 确保debugpy已安装
                vim.fn.system(python_path .. " -m pip install debugpy")

                -- 准备环境变量，包括PYTHONPATH
                local venv = os.getenv("VIRTUAL_ENV")
                local project_root = vim.fn.getcwd()

                require("dap-python").setup(python_path, {
                    -- 调试器配置
                    dap = {
                        justMyCode = false, -- 允许调试第三方库代码
                        console = "integratedTerminal", -- 使用集成终端
                    },
                })

                -- 添加调试配置
                local dap = require("dap")

                -- 清除之前的Python配置
                dap.configurations.python = {}

                -- 设置环境变量
                local env = {
                    -- 确保PYTHONPATH包含当前工作目录
                    PYTHONPATH = project_root,
                }

                -- 如果已有PYTHONPATH，附加到新设置中
                local existing_pythonpath = os.getenv("PYTHONPATH")
                if existing_pythonpath then
                    env.PYTHONPATH = env.PYTHONPATH .. ":" .. existing_pythonpath
                end

                -- 如果存在虚拟环境，添加site-packages路径
                if venv then
                    -- 获取Python版本号
                    local python_version = vim.fn
                        .system(
                            python_path
                                .. " -c 'import sys; print(f\"{sys.version_info.major}.{sys.version_info.minor}\")'"
                        )
                        :gsub("\n", "")
                    local site_packages = venv .. "/lib/python" .. python_version .. "/site-packages"
                    -- 将site-packages添加到PYTHONPATH
                    env.PYTHONPATH = env.PYTHONPATH .. ":" .. site_packages
                end

                -- 标准调试配置（当前文件）
                table.insert(dap.configurations.python, {
                    type = "python",
                    request = "launch",
                    name = "Debug Current File (with env)",
                    program = "${file}",
                    cwd = "${workspaceFolder}",
                    env = env,
                    console = "integratedTerminal",
                    justMyCode = false,
                    pythonPath = python_path,
                })

                -- 带参数的调试配置
                table.insert(dap.configurations.python, {
                    type = "python",
                    request = "launch",
                    name = "Launch with arguments",
                    program = "${file}",
                    args = function()
                        local args_string = vim.fn.input("Arguments: ")
                        return vim.split(args_string, " ")
                    end,
                    cwd = "${workspaceFolder}",
                    env = env,
                    console = "integratedTerminal",
                    justMyCode = false,
                    pythonPath = python_path,
                })

                -- 使用模块调试
                table.insert(dap.configurations.python, {
                    type = "python",
                    request = "launch",
                    name = "Debug Module",
                    module = function()
                        return vim.fn.input("Module name: ")
                    end,
                    cwd = "${workspaceFolder}",
                    env = env,
                    console = "integratedTerminal",
                    justMyCode = false,
                    pythonPath = python_path,
                })

                -- 调试特定入口文件
                table.insert(dap.configurations.python, {
                    type = "python",
                    request = "launch",
                    name = "Debug Entry Point",
                    program = function()
                        return vim.fn.input("Path to script: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    env = env,
                    console = "integratedTerminal",
                    justMyCode = false,
                    pythonPath = python_path,
                })

                -- 添加调试器自己打印的配置信息
                vim.notify(
                    "DAP Python 配置完成:\n路径: " .. python_path .. "\nPYTHONPATH: " .. env.PYTHONPATH,
                    vim.log.levels.INFO
                )
            end

            -- 获取当前Python路径并初始化DAP
            local python_path = get_python_path()
            setup_dap_python(python_path)

            -- 添加自动事件监听器，当venv-selector切换环境时更新DAP
            vim.api.nvim_create_autocmd("User", {
                pattern = "VenvSelectorVenvChanged",
                callback = function()
                    -- 延迟一点执行，确保环境变量已经更新
                    vim.defer_fn(function()
                        local new_python_path = get_python_path()
                        setup_dap_python(new_python_path)
                    end, 100)
                end,
            })

            -- 设置调试器UI
            require("dapui").setup({
                layouts = {
                    {
                        elements = {
                            { id = "scopes", size = 0.25 },
                            { id = "breakpoints", size = 0.25 },
                            { id = "stacks", size = 0.25 },
                            { id = "watches", size = 0.25 },
                        },
                        position = "left",
                        size = 40,
                    },
                    {
                        elements = {
                            { id = "repl", size = 1 },
                        },
                        position = "bottom",
                        size = 10,
                    },
                },
            })
            -- 设置虚拟文本显示
            require("nvim-dap-virtual-text").setup({
                enabled = true,
                display_callback = function(variable, _buf, _stackframe, _node)
                    return string.format(" %s = %s", variable.name, variable.value)
                end,
                highlight_changed_variables = true,
                highlight_new_as_changed = true,
                show_stop_reason = true,
                commented = false,
                only_first_definition = true,
                all_references = false,
                filter_references_pattern = "<module",
                -- 实验性功能
                virt_text_pos = "eol",
                all_frames = false,
                virt_lines = false,
                virt_text_win_col = nil,
            })
            -- 设置调试器快捷键
            vim.keymap.set("n", "<leader>db", function()
                require("dap").toggle_breakpoint()
            end, { desc = "调试: 切换断点" })
            vim.keymap.set("n", "<leader>dB", function()
                require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
            end, { desc = "调试: 设置条件断点" })
            vim.keymap.set("n", "<leader>dc", function()
                require("dap").continue()
            end, { desc = "调试: 继续" })
            vim.keymap.set("n", "<leader>do", function()
                require("dap").step_over()
            end, { desc = "调试: 单步跳过" })
            vim.keymap.set("n", "<leader>di", function()
                require("dap").step_into()
            end, { desc = "调试: 单步进入" })
            vim.keymap.set("n", "<leader>dr", function()
                require("dap").repl.open()
            end, { desc = "调试: 打开REPL" })
            vim.keymap.set("n", "<leader>dl", function()
                require("dap").run_last()
            end, { desc = "调试: 运行上次" })
            vim.keymap.set("n", "<leader>du", function()
                require("dapui").toggle()
            end, { desc = "调试: 切换UI" })
        end,
    },

    -- 添加一个工具命令，用于查看当前DAP配置状态
    {
        "folke/which-key.nvim",
        optional = true,
        opts = {
            defaults = {
                ["<leader>pd"] = { name = "+Python调试信息" },
            },
        },
    },

    {
        "nvim-lua/plenary.nvim",
        config = function()
            -- 创建一个命令查看当前DAP状态
            vim.api.nvim_create_user_command("PythonDebugInfo", function()
                local venv = os.getenv("VIRTUAL_ENV") or "未设置"
                local pythonpath = os.getenv("PYTHONPATH") or "未设置"

                -- 获取DAP当前设置
                local dap = require("dap")
                local python_config = dap.configurations.python or {}
                local dap_python_path = "未设置"

                -- 尝试获取当前Python路径
                if #python_config > 0 and python_config[1].pythonPath then
                    dap_python_path = python_config[1].pythonPath
                end

                -- 创建一个漂亮的输出
                local info = {
                    "Python调试环境信息:",
                    "-------------------",
                    "虚拟环境: " .. venv,
                    "DAP Python路径: " .. dap_python_path,
                    "PYTHONPATH: " .. pythonpath,
                    "-------------------",
                    "DAP配置项:",
                }

                -- 添加每个DAP配置
                for i, config in ipairs(python_config) do
                    table.insert(info, i .. ". " .. (config.name or "未命名"))
                end

                -- 显示信息
                vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
            end, {})

            -- 为它添加一个快捷键
            vim.keymap.set("n", "<leader>pdi", ":PythonDebugInfo<CR>", { desc = "显示Python调试信息" })

            -- 创建一个命令安装debugpy到当前环境
            vim.api.nvim_create_user_command("InstallDebugpy", function()
                local venv = os.getenv("VIRTUAL_ENV")
                if not venv then
                    vim.notify("未检测到激活的Python虚拟环境", vim.log.levels.ERROR)
                    return
                end

                local python_path = venv .. "/bin/python"

                -- 安装debugpy
                vim.fn.system(python_path .. " -m pip install debugpy")
                vim.notify("已尝试安装debugpy到 " .. venv, vim.log.levels.INFO)
            end, {})

            -- 添加快捷键
            vim.keymap.set("n", "<leader>pdd", ":InstallDebugpy<CR>", { desc = "安装Debugpy到当前环境" })
        end,
    },
    {
        -- 智能语法高亮和自动缩进
        "nvim-treesitter/nvim-treesitter",
        ft = "python",
        config = function()
            require("nvim-treesitter.configs").setup({
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = true },
                -- 增强的选择功能
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<C-space>",
                        node_incremental = "<C-space>",
                        scope_incremental = "<nop>",
                        node_decremental = "<bs>",
                    },
                },
            })
        end,
    },
    {
        -- Python补全增强插件
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            -- Python API文档支持
            "hrsh7th/cmp-nvim-lsp-document-symbol",
            -- Python语言服务器补全
            "hrsh7th/cmp-nvim-lsp",
            -- Python模块路径补全
            "hrsh7th/cmp-path",
            -- Python缓冲区补全
            "hrsh7th/cmp-buffer",
            -- Python代码片段支持
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            -- Python docstring补全
            "hrsh7th/cmp-nvim-lsp-signature-help",
            -- Python标签补全
            "hrsh7th/cmp-cmdline",
            -- 更好的排序算法
            "lukas-reineke/cmp-under-comparator",
            -- 类型提示支持
            "onsails/lspkind.nvim",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local lspkind = require("lspkind")

            -- 载入Python特定的代码片段
            require("luasnip.loaders.from_vscode").lazy_load({
                paths = { "./snippets/python" },
            })

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete({}),
                    ["<CR>"] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp", priority = 1000 },
                    { name = "nvim_lsp_signature_help", priority = 900 },
                    { name = "luasnip", priority = 750 },
                    { name = "buffer", priority = 500 },
                    { name = "path", priority = 250 },
                }),
                -- 高级UI功能
                formatting = {
                    format = lspkind.cmp_format({
                        mode = "symbol_text",
                        maxwidth = 50,
                        ellipsis_char = "...",
                        show_labelDetails = true,
                        -- Python特定图标
                        symbol_map = {
                            Class = "🐍 ",
                            Function = "λ ",
                            Method = "𝓜 ",
                            Module = "📦 ",
                            Variable = "𝒙 ",
                            Property = "🏠 ",
                            Keyword = "🔑 ",
                        },
                    }),
                },
                sorting = {
                    comparators = {
                        cmp.config.compare.offset,
                        cmp.config.compare.exact,
                        cmp.config.compare.score,
                        require("cmp-under-comparator").under,
                        cmp.config.compare.kind,
                        cmp.config.compare.sort_text,
                        cmp.config.compare.length,
                        cmp.config.compare.order,
                    },
                },
                experimental = {
                    ghost_text = { hl_group = "CmpGhostText" },
                },
            })

            -- Python文件特定的命令行补全配置
            cmp.setup.filetype("python", {
                sources = cmp.config.sources({
                    { name = "nvim_lsp", priority = 1000 },
                    { name = "nvim_lsp_signature_help", priority = 900 },
                    { name = "luasnip", priority = 750 },
                    { name = "buffer", priority = 500 },
                    { name = "path", priority = 250 },
                }),
            })
        end,
    },
    {
        -- Python导入自动处理
        "mhartington/formatter.nvim",
        ft = "python",
        config = function()
            require("formatter").setup({
                filetype = {
                    python = {
                        -- 使用isort优化导入
                        function()
                            return {
                                exe = "isort",
                                args = { "--profile", "black", "-" },
                                stdin = true,
                            }
                        end,
                        -- 使用autoflake删除未使用的导入
                        function()
                            return {
                                exe = "autoflake",
                                args = {
                                    "--remove-all-unused-imports",
                                    "--remove-unused-variables",
                                    "-",
                                },
                                stdin = true,
                            }
                        end,
                    },
                },
            })
            -- 设置自动格式化导入命令
            vim.api.nvim_create_user_command("PythonFixImports", function()
                vim.cmd("Format")
            end, {})
            -- 快捷键
            vim.keymap.set("n", "<leader>pf", ":PythonFixImports<CR>", { desc = "修复Python导入(使用formatter)" })
        end,
    },
    {
        -- LSP增强功能
        "nvimdev/lspsaga.nvim",
        event = "LspAttach",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("lspsaga").setup({
                lightbulb = {
                    enable = true,
                    sign = true,
                    virtual_text = true,
                },
                code_action = {
                    show_server_name = true,
                    extend_gitsigns = true,
                },
                -- 文档和引用浮动窗口设置
                ui = {
                    border = "rounded",
                    code_action = "💡",
                },
                -- 悬停窗口设置
                hover = {
                    max_width = 0.6,
                    open_link = "gx",
                    open_browser = "!chrome",
                },
                -- 定义/引用查看器
                definition = {
                    width = 0.6,
                    height = 0.4,
                },
                -- 查找引用窗口设置
                finder = {
                    default = "ref+def+imp",
                    layout = "float",
                },
                -- Python特定键映射
                symbol_in_winbar = {
                    enable = true,
                    separator = " > ",
                    hide_keyword = true,
                    show_file = true,
                    folder_level = 1,
                },
            })

            -- Python特定的LSP快捷键
            vim.keymap.set("n", "gh", "<cmd>Lspsaga hover_doc<CR>", { desc = "查看文档" })
            vim.keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<CR>", { desc = "转到定义" })
            vim.keymap.set("n", "gr", "<cmd>Lspsaga finder<CR>", { desc = "查找引用" })
            vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc = "代码操作" })
            vim.keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", { desc = "重命名" })
            vim.keymap.set("n", "<leader>cd", "<cmd>Lspsaga show_cursor_diagnostics<CR>", { desc = "光标诊断" })

            -- 视觉模式下的快速修复功能
            vim.keymap.set("v", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc = "视觉模式代码操作" })

            -- 添加详细的Python智能修复说明
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "python",
                callback = function()
                    -- 当光标停留在有诊断的行时，显示一个提示
                    vim.api.nvim_create_autocmd("CursorHold", {
                        buffer = 0,
                        callback = function()
                            local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
                        end,
                    })
                end,
            })
        end,
    },
    {
        -- 类型提示与错误高亮
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<leader>xx", "<cmd>TroubleToggle<CR>", desc = "切换诊断窗口" },
            { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<CR>", desc = "工作区诊断" },
            { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<CR>", desc = "文档诊断" },
        },
        config = function()
            require("trouble").setup({
                position = "bottom",
                icons = true,
                auto_open = false,
                auto_close = false,
                use_diagnostic_signs = true,
                -- 自动将行分组
                group = true,
                padding = true,
            })
        end,
    },
    {
        -- Python项目结构导航
        "nvim-neo-tree/neo-tree.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        cmd = "Neotree",
        keys = {
            { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "打开项目导航器" },
        },
        config = function()
            require("neo-tree").setup({
                close_if_last_window = true,
                enable_git_status = true,
                enable_diagnostics = true,
                filesystem = {
                    filtered_items = {
                        visible = false,
                        hide_dotfiles = false,
                        hide_gitignored = false,
                        hide_by_name = {
                            "__pycache__",
                            ".pytest_cache",
                            ".git",
                            ".DS_Store",
                        },
                        never_show = {
                            ".pyc",
                        },
                    },
                    follow_current_file = true,
                },
            })
        end,
    },
    {
        -- 文件大纲和函数浏览
        "stevearc/aerial.nvim",
        ft = { "python" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            { "<leader>o", "<cmd>AerialToggle!<CR>", desc = "切换代码大纲" },
        },
        config = function()
            require("aerial").setup({
                layout = {
                    min_width = 30,
                },
                filter_kind = {
                    "Class",
                    "Constructor",
                    "Function",
                    "Method",
                    "Module",
                },
                -- 自动关闭
                close_automatic_events = { "unfocus" },
                -- 显示所有层级
                show_guides = true,
                -- 高亮当前光标位置的符号
                highlight_on_hover = true,
                -- 自动跳转到光标所在的符号
                autojump = true,
            })
        end,
    },
    {
        -- Python类型注解辅助工具
        "Vimjas/vim-python-pep8-indent",
        ft = "python",
    },
    {
        -- Python文档字符串生成
        "danymat/neogen",
        dependencies = "nvim-treesitter/nvim-treesitter",
        keys = {
            { "<leader>pd", ":lua require('neogen').generate()<CR>", desc = "生成Python文档字符串" },
        },
        config = function()
            require("neogen").setup({
                enabled = true,
                languages = {
                    python = {
                        template = {
                            annotation_convention = "numpydoc", -- 支持 "numpydoc", "google", "reST"
                        },
                    },
                },
            })
        end,
    },
    {
        -- 依赖管理集成 (requirements.txt, pyproject.toml)
        "AckslD/nvim-pytrize.lua",
        ft = { "python", "toml" },
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>pr", "<cmd>Pytrize<CR>", desc = "显示pytest参数" },
            { "<leader>pj", "<cmd>PytrizeJump<CR>", desc = "跳转到pytest参数" },
        },
        config = function()
            require("pytrize").setup({})
        end,
    },
    {
        -- 项目特定配置支持
        "folke/neoconf.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("neoconf").setup({
                -- 支持项目级配置
                local_settings = {
                    ".vim/settings.json",
                    ".vim/settings.lua",
                    ".vscode/settings.json",
                    "pyrightconfig.json",
                },
            })
        end,
    },
    {
        -- Python开发任务运行器
        "stevearc/overseer.nvim",
        keys = {
            { "<leader>pt", "<cmd>OverseerRun<CR>", desc = "运行Python任务" },
        },
        config = function()
            require("overseer").setup({
                -- 添加Python特定的任务模板
                templates = {
                    "builtin.python.run_script",
                    "builtin.python.run_test",
                },
                -- 自动检测项目类型
                auto_detect = true,
            })
        end,
    },
    {
        -- 新增：智能导包工具
        "ludovicchabant/vim-gutentags",
        ft = { "python" },
        config = function()
            vim.g.gutentags_enabled = 1
            vim.g.gutentags_generate_on_new = 1
            vim.g.gutentags_generate_on_missing = 1
            vim.g.gutentags_generate_on_write = 1
            vim.g.gutentags_ctags_extra_args = { "--python-kinds=+cfmvi" }
        end,
    },
}
