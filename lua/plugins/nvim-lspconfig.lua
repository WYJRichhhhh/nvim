-- LSP Support
--
-- 已迁移到 Neovim 0.11 原生 LSP API：用 `vim.lsp.config()` 声明配置、
-- `vim.lsp.enable()` 启用，不再调用已废弃的 `require("lspconfig")[server].setup()`。
-- nvim-lspconfig 仍然需要（它在 runtimepath 的 lsp/*.lua 里提供每个 server 的
-- 默认配置：cmd / filetypes / root_markers / 自带命令等），我们只在其之上做覆盖。
--
-- 合并语义（来自 nvim 运行时 lua/vim/lsp.lua）：
--   resolved = tbl_deep_extend("force", config["*"], lsp/<name>.lua, 我们的覆盖)
-- 注意这是“深合并 + force”，对函数字段（on_attach/before_init/on_init）是“整体替换”，
-- 所以覆盖时不要顺手重写 server 自带的这些钩子，否则会丢掉它内置的功能。
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
    config = function()
        -- 全局默认：把 nvim-cmp 的补全能力合并进“所有” server。
        -- vim.lsp.config("*", …) 是最低优先级的基底，各 server 配置会叠在其上。
        -- （旧配置里这段 capabilities 其实从未生效——它只在 opts.servers 上循环，
        --  而本插件 spec 没有定义 opts，循环是空操作；迁移时顺手修正。）
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        vim.lsp.config("*", {
            capabilities = capabilities,
        })

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

        -- 设置 :LspInfo 浮窗的边框为圆角（lspconfig 仍提供该命令）。
        -- 直接 require 子模块，不会触发 lspconfig 框架的废弃告警。
        require("lspconfig.ui.windows").default_options.border = "rounded"

        -- LSP 跳转键 gd/gi/gt/gr 统一在 core/keymaps.lua 全局定义。
        -- 这里原先用 LspAttach 又定义了一份 buffer 局部映射，会覆盖全局版，
        -- 还把 gr 改回原生 references（与全局选用的 telescope.lsp_references 相悖），
        -- 属冗余且有害，故移除。

        -- 无需额外配置的 LSP 服务器：直接用 lsp/<name>.lua 里的默认配置即可，
        -- 这里不需要 vim.lsp.config 覆盖，只要在最后 enable 它们。
        -- （docker/templ/solargraph 等保持原样注释停用。）

        -- Go
        vim.lsp.config("gopls", {
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
        -- lsp/bicep.lua 默认不带 cmd（nvim-lspconfig 不假设你的 PATH），必须显式给出。
        local bicep_path = vim.fn.stdpath("data") .. "/mason/packages/bicep-lsp/bicep-lsp"
        vim.lsp.config("bicep", {
            cmd = { bicep_path },
        })

        -- Lua
        -- 注意：lsp/lua_ls.lua 默认没有 on_init，这里属于纯新增，不会覆盖内置钩子。
        vim.lsp.config("lua_ls", {
            on_init = function(client)
                -- 获取当前工作区的路径。
                -- 原生 LSP API 下，无项目根（如打开游离的单文件）时 workspace_folders 为 nil，
                -- 旧的 lspconfig 框架则总会填充它；这里加防御，无工作区时直接跳过。
                local folders = client.workspace_folders
                if not folders or not folders[1] then
                    return true
                end
                local path = folders[1].name
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
        vim.lsp.config("pyright", {
            -- 原生 root_dir 的新签名是 function(bufnr, on_dir)：异步地把根目录交给 on_dir。
            -- 用我们的标记列表（pyproject.toml / uv.lock 优先），避免漂移到上层 .git。
            root_dir = function(bufnr, on_dir)
                on_dir(py.root(bufnr))
            end,
            -- before_init 在“握手发出前”根据这次的工作区根注入解释器路径，
            -- 是实现“每个项目用各自 .venv”的关键钩子。
            -- 原生 API 会先解析完 root_dir（函数）再触发 before_init，
            -- 所以这里读 config.root_dir 是可靠的。
            before_init = function(_, config)
                config.settings = config.settings or {}
                config.settings.python = config.settings.python or {}
                config.settings.python.pythonPath = py.venv_python(config.root_dir)
            end,
            -- 注意：不要在这里写 on_attach —— lsp/pyright.lua 自带的 on_attach
            -- 注册了 LspPyrightOrganizeImports / LspPyrightSetPythonPath 命令，
            -- 覆盖 on_attach 会把这两个命令弄丢。
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
        vim.lsp.config("ruff", {
            cmd = { vim.fn.stdpath("data") .. "/mason/bin/ruff", "server" },
            root_dir = function(bufnr, on_dir)
                on_dir(py.root(bufnr))
            end,
            -- Ruff 不做 hover，让 pyright 独占文档悬停，避免两个来源打架。
            -- lsp/ruff.lua 默认没有 on_attach，这里属于纯新增。
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
        -- 只覆盖 settings：lsp/rust_analyzer.lua 自带 before_init（把 settings 同步进
        -- init_options、提供 runnables 等），不要覆盖它。
        vim.lsp.config("rust_analyzer", {
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

        -- 启用所有 server。vim.lsp.enable 会注册 FileType 自动命令，并对已打开的
        -- buffer 立即补触发一次，所以启动后打开的第一个文件也能正常 attach。
        vim.lsp.enable({
            -- 无需额外配置（用 lsp/*.lua 默认）：
            "html",
            "jsonls",
            "nil_ls",
            "ols",
            "tailwindcss",
            "taplo",
            "yamlls",
            -- 有覆盖配置：
            "gopls",
            "bicep",
            "lua_ls",
            "pyright",
            "ruff",
            "rust_analyzer",
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
