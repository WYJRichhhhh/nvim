return {
    "mason-org/mason.nvim",
    dependencies = {
        "mason-org/mason-lspconfig.nvim",
    },
    cmd = "Mason",
    event = "BufReadPre",
    keys = { { "<leader>cm", ":Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    config = function()
        require("mason").setup({
            ui = {
                border = "rounded",
                width = 0.8,
                height = 0.8,
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        })

        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "pyright",
                "rust_analyzer",
                "gopls",
                "html",
                "cssls",
                "ts_ls", -- 旧名 tsserver 已废弃，新版 mason-lspconfig 不再识别
                "bashls",
                "jsonls",
                "yamlls",
            },
            -- 本配置里所有 LSP 都在 nvim-lspconfig.lua 显式 setup，
            -- 新版 mason-lspconfig 默认还会再 vim.lsp.enable() 一遍已安装的 server，
            -- 导致 ruff/pyright 等被启动两次（出现重复 client）。关掉它。
            automatic_enable = false,
        })

        local mason_packages = {
            "debugpy",
            "bicep-lsp",
            "docker-compose-language-service",
            "dockerfile-language-server",
            "goimports-reviser",
            "golines",
            "jq",
            "json-lsp",
            "markdownlint-cli2",
            "ols",
            "powershell-editor-services",
            "prettier",
            "ruff",
            "shfmt",
            "stylua",
            "tailwindcss-language-server",
            "taplo",
            "templ",
            "yaml-language-server",
        }

        -- nil 的构建会调用 nix；未安装 Nix 时每次打开文件都会反复编译失败。
        if vim.fn.executable("nix") == 1 then
            table.insert(mason_packages, "nil")
        end

        local mr = require("mason-registry")
        local function ensure_installed()
            for _, tool in ipairs(mason_packages) do
                local ok, p = pcall(mr.get_package, tool)
                if not ok then
                    vim.notify("Mason 找不到工具: " .. tool, vim.log.levels.WARN)
                elseif not p:is_installed() then
                    p:install()
                end
            end
        end
        if mr.refresh then
            mr.refresh(ensure_installed)
        else
            ensure_installed()
        end

    end,
}
