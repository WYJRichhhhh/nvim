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
            "docker_compose_language_service",
            "dockerls",
            "html",
            "jsonls",
            "nil_ls",
            "ols",
            "tailwindcss",
            "taplo",
            "templ", -- requires gopls in PATH, mason probably won't work depending on the OS
            "yamlls",
            "solargraph",
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

        -- Python
        lspconfig.pyright.setup({
            root_dir = require("lspconfig").util.root_pattern(".git", "pyrightconfig.json"),
            settings = {
                pyright = {
                    -- 禁用导入整理，交给Ruff处理
                    disableOrganizeImports = true,
                },
                python = {
                    analysis = {
                        typeCheckingMode = "basic",
                        autoSearchPaths = true,
                        useLibraryCodeForTypes = true,
                        diagnosticMode = "workspace",
                        autoImportCompletions = true,
                        -- 设置诊断覆盖，避免与Ruff重复
                        diagnosticSeverityOverrides = {
                            -- 降低某些诊断的严重性或完全禁用那些Ruff已处理的
                            reportUnusedImport = "none", -- 禁用未使用导入的报告，交给Ruff
                            reportUnusedVariable = "warning", -- 保留为警告
                        },
                    },
                    -- 设置Python路径
                    pythonPath = os.getenv("VIRTUAL_ENV") and os.getenv("VIRTUAL_ENV") .. "/bin/python" or "/usr/bin/python3",
                    -- 设置额外的Python路径
                    extraPaths = {
                        vim.fn.getcwd(),
                        os.getenv("VIRTUAL_ENV") and os.getenv("VIRTUAL_ENV") .. "/lib/python*/site-packages" or "",
                    },
                },
            },
            -- 启用更丰富的capabilities，确保code_action功能
            capabilities = (function()
                -- 关键配置：使用标记系统标识Pyright的诊断
                local capabilities = vim.lsp.protocol.make_client_capabilities()
                capabilities.textDocument.publishDiagnostics.tagSupport.valueSet = { 2 }
                capabilities.textDocument.codeAction = {
                    dynamicRegistration = true,
                    codeActionLiteralSupport = {
                        codeActionKind = {
                            valueSet = {
                                "quickfix",
                                "refactor",
                                "refactor.extract",
                                "refactor.inline",
                                "refactor.rewrite",
                                "source",
                                "source.organizeImports",
                            }
                        }
                    }
                }
                return capabilities
            end)(),
        })

        -- Ruff - 更快的Python linter和formatter (使用新的ruff server而非ruff_lsp)
        lspconfig.ruff.setup({
            capabilities = capabilities,
            settings = {
                -- 使与pyright相同的Python配置
                python = {
                    pythonPath = os.getenv("VIRTUAL_ENV") and os.getenv("VIRTUAL_ENV") .. "/bin/python" or "/usr/bin/python3",
                    extraPaths = {
                        vim.fn.getcwd(),
                        os.getenv("VIRTUAL_ENV") and os.getenv("VIRTUAL_ENV") .. "/lib/python*/site-packages" or "",
                    },
                },
                -- Ruff特定设置
                lint = {
                    enable = true,
                },
                format = {
                    enable = true,
                },
                organizeImports = {
                    enable = true,
                },
                fixAll = {
                    enable = true,
                },
            },
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
                        local diagnostics = vim.diagnostic.get(0, {lnum = line - 1})
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
                    
                    -- Ruff特定设置
                    if client.name == "ruff" then
                        -- 保留完整功能
                    end
                    
                    -- Pyright特定设置
                    if client.name == "pyright" then
                        -- 保留完整功能
                    end
                    
                    -- 为Python文件设置合并显示所有LSP的代码操作
                    if vim.bo[ev.buf].filetype == "python" then
                        -- 覆盖ga快捷键为自定义函数，收集所有服务器的code_actions
                        vim.keymap.set("n", "ga", function()
                            -- 创建请求参数
                            local params = vim.lsp.util.make_range_params()
                            params.context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics() }
                            
                            -- 收集所有响应
                            local results = {}
                            local clients = vim.lsp.get_active_clients({bufnr = ev.buf})
                            local remaining = #clients
                            
                            for _, cl in ipairs(clients) do
                                if cl.server_capabilities.codeActionProvider then
                                    cl.request('textDocument/codeAction', params, function(err, actions, _)
                                        remaining = remaining - 1
                                        
                                        if actions and not err then
                                            -- 标记每个代码操作的来源并添加到结果
                                            for _, action in ipairs(actions) do
                                                action.title = "[" .. cl.name .. "] " .. action.title
                                                table.insert(results, action)
                                            end
                                        end
                                        
                                        -- 当所有服务器都响应后显示合并的actions
                                        if remaining == 0 then
                                            if #results == 0 then
                                                vim.notify("没有可用的代码操作", vim.log.levels.INFO)
                                            else
                                                vim.lsp.buf.code_action({
                                                    actions = results
                                                })
                                            end
                                        end
                                    end, ev.buf)
                                else
                                    remaining = remaining - 1
                                end
                            end
                        end, { buffer = ev.buf, desc = "显示所有代码操作" })
                        
                        -- 为特定服务器提供单独快捷键
                        vim.keymap.set("n", "<leader>ap", function()
                            local params = vim.lsp.util.make_range_params()
                            params.context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics() }
                            
                            local pyright_client = vim.lsp.get_active_clients({name = "pyright", bufnr = ev.buf})[1]
                            if pyright_client then
                                pyright_client.request('textDocument/codeAction', params, function(err, actions, _)
                                    if actions and not err and #actions > 0 then
                                        vim.lsp.buf.code_action({
                                            actions = actions
                                        })
                                    else
                                        vim.notify("没有可用的Pyright代码操作", vim.log.levels.INFO)
                                    end
                                end, ev.buf)
                            else
                                vim.notify("Pyright客户端未连接", vim.log.levels.INFO)
                            end
                        end, { buffer = ev.buf, desc = "仅Pyright代码操作" })
                        
                        vim.keymap.set("n", "<leader>ar", function()
                            local params = vim.lsp.util.make_range_params()
                            params.context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics() }
                            
                            local ruff_client = vim.lsp.get_active_clients({name = "ruff", bufnr = ev.buf})[1]
                            if ruff_client then
                                ruff_client.request('textDocument/codeAction', params, function(err, actions, _)
                                    if actions and not err and #actions > 0 then
                                        vim.lsp.buf.code_action({
                                            actions = actions
                                        })
                                    else
                                        vim.notify("没有可用的Ruff代码操作", vim.log.levels.INFO)
                                    end
                                end, ev.buf)
                            else
                                vim.notify("Ruff客户端未连接", vim.log.levels.INFO)
                            end
                        end, { buffer = ev.buf, desc = "仅Ruff代码操作" })
                    end
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
