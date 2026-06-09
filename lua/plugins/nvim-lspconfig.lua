-- LSP Support
return {
    -- LSP Configuration
    -- https://github.com/neovim/nvim-lspconfig
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        -- LSP Management
        -- https://github.com/williamboman/mason.nvim
        { "williamboman/mason.nvim" },
        -- https://github.com/williamboman/mason-lspconfig.nvim
        { "williamboman/mason-lspconfig.nvim" },

        -- LSP补全集成
        { "hrsh7th/cmp-nvim-lsp" },

        -- Useful status updates for LSP
        -- https://github.com/j-hui/fidget.nvim
        { "j-hui/fidget.nvim", opts = {} },

        -- Additional lua configuration, makes nvim stuff amazing!
        -- https://github.com/folke/neodev.nvim
        { "folke/neodev.nvim" },
        {
            "folke/lazydev.nvim",
            ft = "lua",
            opts = {
                library = {
                    { path = "luvit-meta/library", words = { "vim%.uv" } },
                },
            },
        },
        "Bilal2453/luvit-meta",
        "smiteshp/nvim-navic",
        -- { "saghen/blink.cmp" },
    },
    config = function(_, opts)
        -- 使用nvim-cmp的LSP能力提供补全
        local lspconfig = require("lspconfig")
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        for server, config in pairs(opts.servers or {}) do
            config.capabilities = vim.tbl_deep_extend("force", capabilities, config.capabilities or {})
            lspconfig[server].setup(config)
        end
        -- 用于管理mason.nvim的插件的注册表。包含了可以安装的所有LSP服务器。
        local mason_registry = require("mason-registry")
        -- 设置lspconfig.ui的的边框为圆角
        require("lspconfig.ui.windows").default_options.border = "rounded"

        -- 诊断配置
        vim.diagnostic.config({
            float = { border = "rounded" }, -- 为诊断框添加圆角边框
            signs = true, -- 行号前显示错误标志
            underline = true, -- 有问题代码添加下划线
            update_in_insert = true, -- 插入模式下更新诊断信息
            virtual_text = { -- 诊断的虚拟文本的格式
                source = "if_many", -- 仅在诊断较多时显示
                prefix = "●",
            },
        })

        -- 设置LSP快捷键
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                -- 跳转到实现
                vim.keymap.set("n", "gi", function()
                    vim.lsp.buf.implementation()
                end, { buffer = ev.buf, desc = "跳转到实现" })

                -- 跳转到定义
                vim.keymap.set("n", "gd", function()
                    vim.lsp.buf.definition()
                end, { buffer = ev.buf, desc = "跳转到定义" })

                -- 跳转到类型定义
                vim.keymap.set("n", "gt", function()
                    vim.lsp.buf.type_definition()
                end, { buffer = ev.buf, desc = "跳转到类型定义" })

                -- 跳转到引用
                vim.keymap.set("n", "gr", function()
                    vim.lsp.buf.references()
                end, { buffer = ev.buf, desc = "跳转到引用" })
            end,
        })

        -- 无需配置的LSP服务器
        local no_config_servers = {
            -- "docker_compose_language_service",
            -- "dockerls",
            "html",
            "jsonls",
            "nil_ls",
            "ols",
            "tailwindcss",
            "taplo",
            -- "templ", -- requires gopls in PATH, mason probably won't work depending on the OS
            "yamlls",
            -- "solargraph",
        }

        -- 加载所有无需配置的LSP服务器
        for _, server in pairs(no_config_servers) do
            require("lspconfig")[server].setup({})
        end

        local lspconfig = require("lspconfig")

        -- Go
        lspconfig.gopls.setup({
            settings = {
                gopls = {
                    completeUnimported = true,
                    analyses = {
                        unusedparams = true,
                    },
                    staticcheck = true,
                },
            },
        })

        -- Bicep Azure 资源语言
        local bicep_path = vim.fn.stdpath("data") .. "/mason/packages/bicep-lsp/bicep-lsp"
        lspconfig.bicep.setup({
            cmd = { bicep_path },
        })

        -- Lua
        lspconfig.lua_ls.setup({
            on_init = function(client)
                -- 获取当前工作区的路径
                local path = client.workspace_folders[1].name
                -- 如果工作区没有.luarc.json或.luarc.jsonc文件，则设置LuaJIT为运行时
                if not vim.uv.fs_stat(path .. "/.luarc.json") and not vim.uv.fs_stat(path .. "/.luarc.jsonc") then
                    -- 强制新配置合并到现有配置中
                    client.config.settings = vim.tbl_deep_extend("force", client.config.settings, {
                        Lua = {
                            -- 这是nvim使用的lua版本
                            runtime = {
                                version = "LuaJIT",
                            },
                            -- 禁用三方库检查
                            -- 将nvim的运行时文件加入到lua的library中，以便于查找nvim的API
                            workspace = {
                                checkThirdParty = false,
                                library = vim.api.nvim_get_runtime_file("", true),
                            },
                        },
                    })

                    -- 将上面的配置发送给LSP服务器 以应用新的配置
                    client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
                end
                return true
            end,
        })

        -- Python --------------------------------------------------------------
        -- 关键点：解释器不写死，而是在每个 buffer 启动 LSP 前，
        -- 从“文件所属的项目根”推断出对应的 .venv/bin/python（见 core/python.lua）。
        -- 这样从任意目录打开任意 uv 项目，pyright 都能锁定到该项目自己的环境。
        local py = require("core.python")

        -- pyright：负责类型检查、跳转定义/引用、补全、悬停文档。
        lspconfig.pyright.setup({
            -- root_dir 决定 LSP 把哪个目录当作工作区根。
            -- 用我们的标记列表（pyproject.toml / uv.lock 优先），避免漂移到上层 .git。
            root_dir = function(fname)
                return py.root(fname)
            end,
            -- before_init 在“握手发出前”根据这次的工作区根注入解释器路径，
            -- 是实现“每个项目用各自 .venv”的关键钩子。
            before_init = function(_, config)
                config.settings = config.settings or {}
                config.settings.python = config.settings.python or {}
                config.settings.python.pythonPath = py.venv_python(config.root_dir)
            end,
            settings = {
                -- 导入整理交给 Ruff，避免和 Ruff 抢同一个 code action。
                pyright = { disableOrganizeImports = true },
                python = {
                    analysis = {
                        typeCheckingMode = "basic",
                        autoSearchPaths = true,
                        useLibraryCodeForTypes = true,
                        diagnosticMode = "openFilesOnly", -- 只诊断打开的文件，避免大项目卡顿
                        autoImportCompletions = true,
                        diagnosticSeverityOverrides = {
                            -- 未使用导入/变量交给 Ruff 报，pyright 这里关掉避免重复。
                            reportUnusedImport = "none",
                            reportUnusedVariable = "none",
                        },
                    },
                },
            },
        })

        -- Ruff：负责 lint + 自动修复 + import 排序，比 flake8/isort 快很多。
        -- 用 mason 装的 ruff 二进制（自带的 `ruff server`，不是已废弃的 ruff_lsp）。
        lspconfig.ruff.setup({
            cmd = { vim.fn.stdpath("data") .. "/mason/bin/ruff", "server" },
            root_dir = function(fname)
                return py.root(fname)
            end,
            -- Ruff 不做 hover，让 pyright 独占文档悬停，避免两个来源打架。
            on_attach = function(client, _)
                client.server_capabilities.hoverProvider = false
            end,
        })

        -- 添加LSP客户端功能区分 - 在LspAttach事件中
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspActions", {}),
            callback = function(ev)
                local client = vim.lsp.get_client_by_id(ev.data.client_id)
                if client then
                    -- 添加函数显示当前行诊断来源
                    vim.keymap.set("n", "<leader>ls", function()
                        local line = vim.fn.line(".")
                        local diagnostics = vim.diagnostic.get(0, { lnum = line - 1 })
                        if #diagnostics > 0 then
                            local sources = {}
                            for _, diag in ipairs(diagnostics) do
                                table.insert(sources, diag.source or "未知来源")
                            end
                            local uniq_sources = {}
                            for _, src in ipairs(sources) do
                                uniq_sources[src] = true
                            end
                            local sources_str = "诊断来源: "
                            for src, _ in pairs(uniq_sources) do
                                sources_str = sources_str .. src .. ", "
                            end
                            vim.notify(sources_str:sub(1, -3), vim.log.levels.INFO)
                        else
                            vim.notify("当前行没有诊断信息", vim.log.levels.INFO)
                        end
                    end, { buffer = ev.buf, desc = "显示当前行诊断来源" })
                end
            end,
        })

        -- Rust
        lspconfig.rust_analyzer.setup({
            settings = {
                ["rust-analyzer"] = {
                    checkOnSave = {
                        command = "clippy",
                    },
                    cargo = {
                        loadOutDirsFromCheck = true,
                    },
                },
            },
        })
        -- Globally configure all LSP floating preview popups (like hover, signature help, etc)
        local open_floating_preview = vim.lsp.util.open_floating_preview
        function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
            opts = opts or {}
            opts.border = opts.border or "rounded" -- Set border to rounded
            return open_floating_preview(contents, syntax, opts, ...)
        end
    end,
}
