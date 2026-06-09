-- Python 调试（DAP）。
-- LSP 在 nvim-lspconfig.lua 里配置；这里只管调试。
-- 两边共用 core/python.lua 的解析逻辑，保证“调试用的解释器”和
-- “LSP 用的解释器”永远是同一个 —— 否则会出现 LSP 不报错、一调试就
-- ModuleNotFoundError 的诡异情况。
return {
    {
        "mfussenegger/nvim-dap-python",
        ft = "python",
        dependencies = {
            "mfussenegger/nvim-dap",
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "theHamsta/nvim-dap-virtual-text",
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            local py = require("core.python")

            -- dap-python 默认用 $VIRTUAL_ENV / CONDA_PREFIX 找解释器；
            -- 我们用 resolve_python 钩子接管，改成“从当前文件推断项目根 -> .venv”。
            -- setup 的第一个参数是“启动调试适配器(debugpy.adapter)用的解释器”，
            -- 它只需要能 import debugpy 即可；真正运行被调试代码用的是各 config 里的 pythonPath。
            local dap_python = require("dap-python")
            dap_python.resolve_python = function()
                return py.venv_python(py.root())
            end
            dap_python.setup(py.venv_python(py.root()), {
                include_configs = true, -- 提供 file / file:args / attach 等默认配置
                console = "integratedTerminal",
            })

            -- 让每个启动配置在“按下调试键的那一刻”根据当前文件重新解析解释器，
            -- 这样在多个 uv 项目间切换 buffer 时不会用错环境。
            for _, cfg in ipairs(dap.configurations.python or {}) do
                cfg.pythonPath = function()
                    return py.venv_python(py.root())
                end
                cfg.justMyCode = false -- 允许步入第三方库
                cfg.cwd = "${workspaceFolder}"
            end

            -- 调试 UI：开始调试自动开，结束自动关。
            dapui.setup()
            dap.listeners.after.event_initialized["dapui"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui"] = function()
                dapui.close()
            end

            require("nvim-dap-virtual-text").setup({
                commented = false,
                virt_text_pos = "eol",
            })

            -- 调试快捷键
            local map = vim.keymap.set
            map("n", "<leader>db", dap.toggle_breakpoint, { desc = "调试: 切换断点" })
            map("n", "<leader>dB", function()
                dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
            end, { desc = "调试: 条件断点" })
            map("n", "<leader>dc", dap.continue, { desc = "调试: 启动/继续" })
            map("n", "<leader>do", dap.step_over, { desc = "调试: 单步跳过" })
            map("n", "<leader>di", dap.step_into, { desc = "调试: 单步进入" })
            map("n", "<leader>dO", dap.step_out, { desc = "调试: 单步跳出" })
            map("n", "<leader>dr", dap.repl.toggle, { desc = "调试: REPL" })
            map("n", "<leader>dl", dap.run_last, { desc = "调试: 运行上次" })
            map("n", "<leader>du", dapui.toggle, { desc = "调试: 切换 UI" })
            map("n", "<leader>dt", dap.terminate, { desc = "调试: 终止" })

            -- 把 debugpy 装进“当前项目对应的 .venv”。
            -- uv 项目推荐：在项目里执行 `uv add --dev debugpy`（会写进 pyproject）。
            -- 这个命令是临时补救：直接 pip 装进解析出的 venv，不改 pyproject。
            vim.api.nvim_create_user_command("DebugpyInstall", function()
                local python = py.venv_python(py.root())
                vim.notify("正在向 " .. python .. " 安装 debugpy ...", vim.log.levels.INFO)
                vim.system({ python, "-m", "pip", "install", "debugpy" }, {}, function(out)
                    local level = out.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
                    vim.schedule(function()
                        vim.notify(out.code == 0 and "debugpy 安装完成" or ("失败: " .. (out.stderr or "")), level)
                    end)
                end)
            end, { desc = "向当前项目 venv 安装 debugpy" })
        end,
    },
}
