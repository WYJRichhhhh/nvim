return {
    "NvChad/nvterm",
    config = function()
        -- 获取当前目录下的虚拟环境路径
        local function get_venv_path()
            local cwd = vim.fn.getcwd()
            local venv_paths = {
                cwd .. "/.venv",
                cwd .. "/venv",
                cwd .. "/env",
                cwd .. "/.env",
            }

            for _, path in ipairs(venv_paths) do
                if vim.fn.isdirectory(path) == 1 then
                    return path
                end
            end
            return nil
        end

        -- 生成激活虚拟环境的命令
        local function get_activate_cmd()
            local venv_path = get_venv_path()
            if not venv_path then
                return ""
            end

            if vim.fn.has("win32") == 1 then
                return string.format("source %s/Scripts/activate", venv_path)
            else
                return string.format("source %s/bin/activate", venv_path)
            end
        end

        require("nvterm").setup({
            terminals = {
                shell = vim.o.shell,
                list = {},
                list_active = {},
                type_opts = {
                    float = {
                        relative = "editor",
                        row = 0.1,
                        col = 0.1,
                        width = 0.8,
                        height = 0.8,
                        x = 0.5,
                        y = 0.5,
                        anchor = "NE",
                        style = "minimal",
                        border = "double",
                        title = "Terminal",
                        title_pos = "center",
                        highlights = {
                            border = "FloatBorder",
                            background = "Normal",
                        },
                    },
                    horizontal = {
                        location = "rightbelow",
                        split_ratio = 0.3,
                        border = "single",
                    },
                    vertical = {
                        location = "rightbelow",
                        split_ratio = 0.5,
                        border = "single",
                    },
                },
            },
            behavior = {
                autoclose_on_quit = {
                    enabled = false,
                    confirm = true,
                },
                close_on_exit = true,
                auto_insert = true,
                terminal_mappings = true,
            },
            -- 添加自定义命令
            commands = {
                -- 在终端打开时执行的命令
                on_open = function()
                    -- 只返回清屏命令
                    return "clear"
                end,
            },
        })

        -- 设置快捷键
        local terminal = require("nvterm.terminal")
        local toggle_modes = { "n", "t" }

        -- 初始化终端时设置环境变量
        vim.api.nvim_create_autocmd("TermOpen", {
            callback = function()
                -- 延迟执行环境设置
                vim.defer_fn(function()
                    local venv = os.getenv("VIRTUAL_ENV")
                    if venv then
                        -- 获取项目根目录
                        local project_root = vim.fn.getcwd()

                        -- 检查是否是 pyenv 环境
                        local is_pyenv = string.find(venv, "%.pyenv") ~= nil

                        -- 构建环境切换命令
                        local activate_cmd
                        if is_pyenv then
                            -- 从路径中提取环境名称
                            local venv_name = vim.fn.fnamemodify(venv, ":t")

                            -- 构建激活命令（静默执行）
                            local commands = string.format(
                                [[
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
export VIRTUAL_ENV="%s"
export PYTHONPATH="%s:$PYTHONPATH"
pyenv shell %s 2>/dev/null
clear
]],
                                venv,
                                project_root,
                                venv_name
                            )

                            -- 获取当前终端通道
                            local term_chan = vim.b.terminal_job_id
                            if term_chan then
                                vim.api.nvim_chan_send(term_chan, commands)
                            end
                        else
                            -- 普通虚拟环境
                            local commands = string.format(
                                [[
source %s/bin/activate 2>/dev/null
export PYTHONPATH="%s:$PYTHONPATH"
clear
]],
                                venv,
                                project_root
                            )

                            -- 获取当前终端通道
                            local term_chan = vim.b.terminal_job_id
                            if term_chan then
                                vim.api.nvim_chan_send(term_chan, commands)
                            end
                        end
                    end
                end, 100) -- 延迟100毫秒执行
            end,
        })

        -- 添加终端模式下的快捷键
        vim.api.nvim_create_autocmd("TermEnter", {
            callback = function()
                vim.keymap.set("t", "<C-l>", "<C-\\><C-n>i<C-l>", { buffer = true })
                vim.keymap.set("t", "<C-k>", "clear\n", { buffer = true })
            end,
        })

        -- 监听环境变量变化
        vim.api.nvim_create_autocmd("User", {
            pattern = "VenvSelectorVenvChanged",
            callback = function()
                local venv = os.getenv("VIRTUAL_ENV")
                if venv then
                    -- 获取项目根目录
                    local project_root = vim.fn.getcwd()

                    -- 获取所有终端窗口
                    local terminals = require("nvterm").get_all()
                    for _, term in ipairs(terminals) do
                        -- 检查是否是 pyenv 环境
                        local is_pyenv = string.find(venv, "%.pyenv") ~= nil

                        -- 构建环境切换命令
                        local commands
                        if is_pyenv then
                            -- 从路径中提取环境名称
                            local venv_name = vim.fn.fnamemodify(venv, ":t")

                            -- 构建激活命令
                            commands = string.format(
                                [[
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
export VIRTUAL_ENV="%s"
export PYTHONPATH="%s:$PYTHONPATH"
pyenv shell %s 2>/dev/null
clear
]],
                                venv,
                                project_root,
                                venv_name
                            )
                        else
                            -- 普通虚拟环境
                            commands = string.format(
                                [[
source %s/bin/activate 2>/dev/null
export PYTHONPATH="%s:$PYTHONPATH"
clear
]],
                                venv,
                                project_root
                            )
                        end

                        -- 发送到终端
                        vim.api.nvim_chan_send(term, commands)
                    end
                end
            end,
        })
    end,
}
