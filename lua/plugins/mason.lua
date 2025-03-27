return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
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
        "ruff",
        "rust_analyzer",
        "gopls",
        "html",
        "cssls",
        "typescript-language-server",
        "bashls",
        "jsonls",
        "yamlls",
      },
      automatic_installation = true,
    })

    local linux_only_pacakages = {
      "nil",
    }

    local mason_packages = {
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
      "shfmt",
      "stylua",
      "tailwindcss-language-server",
      "taplo",
      "templ",
      "yaml-language-server",
    }

    if vim.fn.has("win32") == 0 then
      mason_packages = vim.tbl_extend("force", mason_packages, linux_only_pacakages)
    end

    local mr = require("mason-registry")
    local function ensure_installed()
      for _, tool in ipairs(mason_packages) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
          p:install()
        end
      end
    end
    if mr.refresh then
      mr.refresh(ensure_installed)
    else
      ensure_installed()
    end

    vim.api.nvim_create_user_command("SetupPythonTools", function()
      local tools = {
        "pyright",
        "ruff",
        "black",
        "isort",
        "debugpy",
      }
      
      local registry = require("mason-registry")
      
      vim.notify("正在安装Python开发工具...", vim.log.levels.INFO)
      
      for _, tool in ipairs(tools) do
        if not registry.is_installed(tool) then
          vim.notify("安装 " .. tool, vim.log.levels.INFO)
          local pkg = registry.get_package(tool)
          pkg:install()
        else
          vim.notify(tool .. " 已安装", vim.log.levels.INFO)
        end
      end
      
      vim.notify("安装Python pip包...", vim.log.levels.INFO)
      local python_packages = {
        "debugpy",  -- 调试支持
      }
      
      local venv = os.getenv("VIRTUAL_ENV")
      local pip_cmd = venv and venv .. "/bin/pip" or "pip"
      
      for _, pkg in ipairs(python_packages) do
        vim.fn.system(pip_cmd .. " install -U " .. pkg)
      end
      
      vim.notify("Python开发工具安装完成！请重启Neovim以激活所有功能。", vim.log.levels.INFO)
    end, {})
    
    vim.keymap.set("n", "<leader>pm", ":SetupPythonTools<CR>", { desc = "安装Python工具" })
  end,
}
