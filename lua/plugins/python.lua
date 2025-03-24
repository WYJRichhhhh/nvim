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
              -- 设置Python路径
              pythonPath = function()
                local venv = os.getenv("VIRTUAL_ENV")
                if venv then
                  return venv .. "/bin/python"
                end
                return "/usr/bin/python3"
              end,
              -- 设置额外的Python路径
              extraPaths = function()
                local paths = {}
                -- 添加项目根目录
                table.insert(paths, vim.fn.getcwd())
                -- 添加虚拟环境site-packages
                local venv = os.getenv("VIRTUAL_ENV")
                if venv then
                  table.insert(paths, venv .. "/lib/python*/site-packages")
                end
                return paths
              end,
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
    "linux-cultist/venv-selector.nvim",
    ft = "python",
    dependencies = { 
      "neovim/nvim-lspconfig", 
      "nvim-telescope/telescope.nvim" 
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
        auto_refresh_on_write = true,
        -- 新增配置
        search_dir = function()
          return vim.fn.getcwd()
        end,
        -- 自动检测并激活虚拟环境
        auto_refresh_on_write = true,
        -- 在状态栏显示当前环境
        status_line = true,
        -- 在切换环境时自动重启LSP
        post_set_venv = function()
          vim.cmd("LspRestart")
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
        return "/usr/bin/python3"  -- 默认使用系统Python
      end

      -- 设置Python调试器
      require("dap-python").setup(get_python_path(), {
        -- 调试器配置
        dap = {
          justMyCode = false,  -- 允许调试第三方库代码
          console = "integratedTerminal",  -- 使用集成终端
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
      vim.keymap.set("n", "<leader>db", function() require("dap").toggle_breakpoint() end, { desc = "调试: 切换断点" })
      vim.keymap.set("n", "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, { desc = "调试: 设置条件断点" })
      vim.keymap.set("n", "<leader>dc", function() require("dap").continue() end, { desc = "调试: 继续" })
      vim.keymap.set("n", "<leader>do", function() require("dap").step_over() end, { desc = "调试: 单步跳过" })
      vim.keymap.set("n", "<leader>di", function() require("dap").step_into() end, { desc = "调试: 单步进入" })
      vim.keymap.set("n", "<leader>dr", function() require("dap").repl.open() end, { desc = "调试: 打开REPL" })
      vim.keymap.set("n", "<leader>dl", function() require("dap").run_last() end, { desc = "调试: 运行上次" })
      vim.keymap.set("n", "<leader>du", function() require("dapui").toggle() end, { desc = "调试: 切换UI" })
      vim.keymap.set("n", "<leader>dx", function() require("dap").terminate() end, { desc = "调试: 终止" })
      vim.keymap.set("n", "<leader>dC", function() require("dap").clear_breakpoints() end, { desc = "调试: 清除所有断点" })
      vim.keymap.set("n", "<leader>de", function() require("dap").eval() end, { desc = "调试: 评估表达式" })
      vim.keymap.set("n", "<leader>dE", function() require("dap").eval(vim.fn.input("Expression: ")) end, { desc = "调试: 评估输入表达式" })
      vim.keymap.set("n", "<leader>df", function() require("telescope").extensions.dap.frames() end, { desc = "调试: 显示帧" })
      vim.keymap.set("n", "<leader>di", function() require("telescope").extensions.dap.list_breakpoints() end, { desc = "调试: 列出断点" })
      vim.keymap.set("n", "<leader>dS", function() require("telescope").extensions.dap.variables() end, { desc = "调试: 显示变量" })
      vim.keymap.set("n", "<leader>dh", function() require("dap.ui.widgets").hover() end, { desc = "调试: 悬停显示" })
      vim.keymap.set("n", "<leader>d?", function() require("dap.ui.widgets").preview() end, { desc = "调试: 预览" })
      vim.keymap.set("n", "<leader>dc", function() require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes) end, { desc = "调试: 显示作用域" })
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