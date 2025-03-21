-- Python开发环境配置
return {
  {
    -- Python LSP服务器 - 更强大的Python类型检查和自动补全
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    ft = { "python" },
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic", -- 可设置为 "off", "basic", "strict"
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
                -- 自动导入功能
                autoImportCompletions = true,
              },
            },
          },
        },
      },
    },
  },
  {
    -- Ruff LSP - 更快的Python linter和formatter
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    ft = { "python" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        python = { "ruff" },
      }
      -- 保存时自动lint
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
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
    -- Python环境管理
    "ChristianChiarulli/swenv.nvim",
    ft = "python",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("swenv").setup({
        -- 自动检测Python项目虚拟环境
        post_set_venv = function()
          -- 当切换环境时，重启所有Python相关LSP
          vim.cmd("LspRestart")
        end,
      })
      -- 设置快捷键来管理Python环境
      vim.keymap.set("n", "<leader>pe", function() require("swenv.api").pick_venv() end, { desc = "选择Python环境" })
      vim.keymap.set("n", "<leader>pc", function() require("swenv.api").get_current_venv() end, { desc = "显示当前Python环境" })
    end,
  },
  {
    -- Python补全增强
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      -- Python docstring补全
      "hrsh7th/cmp-nvim-lsp-signature-help",
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
        return "/usr/bin/python3"  -- 默认使用系统Python
      end

      -- 设置Python调试器
      require("dap-python").setup(get_python_path())
      
      -- 设置调试器快捷键
      vim.keymap.set("n", "<leader>db", function() require("dap").toggle_breakpoint() end, { desc = "调试: 切换断点" })
      vim.keymap.set("n", "<leader>dc", function() require("dap").continue() end, { desc = "调试: 继续" })
      vim.keymap.set("n", "<leader>do", function() require("dap").step_over() end, { desc = "调试: 单步跳过" })
      vim.keymap.set("n", "<leader>di", function() require("dap").step_into() end, { desc = "调试: 单步进入" })
      vim.keymap.set("n", "<leader>dr", function() require("dap").repl.open() end, { desc = "调试: 打开REPL" })
    end,
  },
  {
    -- 提供Python语法高亮和缩进
    "nvim-treesitter/nvim-treesitter",
    ft = { "python" },
    opts = {
      ensure_installed = { "python" },
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
      },
    },
  },
  {
    -- Python测试框架支持
    "nvim-neotest/neotest",
    ft = "python",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
            -- 自动检测pytest运行器
            runner = "pytest",
            -- 支持测试发现
            pytest_discovery = true,
          }),
        },
      })
      
      -- 设置测试快捷键
      vim.keymap.set("n", "<leader>tt", function() require("neotest").run.run() end, { desc = "测试: 运行最近的测试" })
      vim.keymap.set("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "测试: 运行当前文件" })
      vim.keymap.set("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "测试: 切换摘要" })
    end,
  },
  {
    -- Python代码导航和信息显示
    "SmiteshP/nvim-navic",
    event = "LspAttach",
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("nvim-navic").setup({
        highlight = true,
        lsp = {
          auto_attach = true,
        },
      })
    end,
  },
  {
    -- 提供智能重命名和导入排序
    "ThePrimeagen/refactoring.nvim",
    ft = { "python" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("refactoring").setup({})
      -- 设置重构快捷键
      vim.keymap.set("v", "<leader>re", function() require("refactoring").refactor("Extract Function") end, { desc = "重构: 提取函数" })
      vim.keymap.set("v", "<leader>rv", function() require("refactoring").refactor("Extract Variable") end, { desc = "重构: 提取变量" })
      vim.keymap.set("n", "<leader>ri", function() require("refactoring").refactor("Inline Variable") end, { desc = "重构: 内联变量" })
    end,
  },
  {
    -- 显示代码文档和函数签名
    "ray-x/lsp_signature.nvim",
    event = "LspAttach",
    config = function()
      require("lsp_signature").setup({
        bind = true,
        handler_opts = {
          border = "rounded",
        },
        hint_enable = true,  -- 显示参数名提示
        hint_prefix = "📝 ",
        doc_lines = 10,      -- 文档显示行数
      })
    end,
  },
} 