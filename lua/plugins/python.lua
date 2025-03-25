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
                        -- 获取所有终端窗口
                        local terminals = require("nvterm").get_all()
                        for _, term in ipairs(terminals) do
                            -- 发送激活命令到终端
                            vim.api.nvim_chan_send(term, activate_cmd .. "\n")
                            -- 设置 PYTHONPATH
                            vim.api.nvim_chan_send(
                                term,
                                string.format("export PYTHONPATH=%s:$PYTHONPATH\n", project_root)
                            )
                        end

                        -- 触发环境变化事件
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
            vim.keymap.set("n", "<leader>pi", ":Autoflake<CR>", { desc = "移除未使用的导入" })
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
            require("dap-python").setup(get_python_path(), {
                -- 调试器配置
                dap = {
                    justMyCode = false, -- 允许调试第三方库代码
                    console = "integratedTerminal", -- 使用集成终端
                },
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
}

