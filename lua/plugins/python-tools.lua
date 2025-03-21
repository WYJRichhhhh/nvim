-- Python附加工具配置 - 增强项目导航和代码分析
return {
  {
    -- Python项目结构导航
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<leader>fp", "<cmd>Neotree toggle<CR>", desc = "打开项目导航器" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        enable_git_status = true,
        enable_diagnostics = true,
        filesystem = {
          filtered_items = {
            visible = false,
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_by_name = {
              "__pycache__",
              ".pytest_cache",
              ".git",
              ".DS_Store",
            },
            never_show = {
              ".pyc",
            },
          },
          follow_current_file = true,
        },
      })
    end,
  },
  {
    -- 文件大纲和函数浏览
    "stevearc/aerial.nvim",
    ft = { "python" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>o", "<cmd>AerialToggle!<CR>", desc = "切换代码大纲" },
    },
    config = function()
      require("aerial").setup({
        layout = {
          min_width = 30,
        },
        filter_kind = {
          "Class",
          "Constructor",
          "Function",
          "Method",
          "Module",
        },
        -- 自动关闭
        close_automatic_events = { "unfocus" },
        -- 显示所有层级
        show_guides = true,
        -- 高亮当前光标位置的符号
        highlight_on_hover = true,
        -- 自动跳转到光标所在的符号
        autojump = true,
      })
    end,
  },
  {
    -- Python类型注解辅助工具
    "Vimjas/vim-python-pep8-indent",
    ft = "python",
  },
  {
    -- Python文档字符串生成
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    keys = {
      { "<leader>pd", ":lua require('neogen').generate()<CR>", desc = "生成Python文档字符串" },
    },
    config = function()
      require("neogen").setup({
        enabled = true,
        languages = {
          python = {
            template = {
              annotation_convention = "numpydoc", -- 支持 "numpydoc", "google", "reST"
            },
          },
        },
      })
    end,
  },
  {
    -- 依赖管理集成 (requirements.txt, pyproject.toml)
    "AckslD/nvim-pytrize.lua",
    ft = { "python", "toml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>pr", "<cmd>Pytrize<CR>", desc = "显示pytest参数" },
      { "<leader>pj", "<cmd>PytrizeJump<CR>", desc = "跳转到pytest参数" },
    },
    config = function()
      require("pytrize").setup({})
    end,
  },
  {
    -- 项目特定配置支持
    "folke/neoconf.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("neoconf").setup({
        -- 支持项目级配置
        local_settings = {
          ".vim/settings.json",
          ".vim/settings.lua",
          ".vscode/settings.json",
          "pyrightconfig.json",
        },
      })
    end,
  },
  {
    -- Python开发任务运行器
    "stevearc/overseer.nvim",
    keys = {
      { "<leader>pt", "<cmd>OverseerRun<CR>", desc = "运行Python任务" },
    },
    config = function()
      require("overseer").setup({
        -- 添加Python特定的任务模板
        templates = {
          "builtin.python.run_script",
          "builtin.python.run_test",
        },
        -- 自动检测项目类型
        auto_detect = true,
      })
    end,
  },
  {
    -- 智能注释生成器
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("neogen").setup({
        enabled = true,
        languages = {
          python = {
            template = {
              annotation_convention = "numpydoc",
            },
          },
        },
      })
    end,
  },
  {
    -- 新增：智能导包工具
    "ludovicchabant/vim-gutentags",
    ft = { "python" },
    config = function()
      vim.g.gutentags_enabled = 1
      vim.g.gutentags_generate_on_new = 1
      vim.g.gutentags_generate_on_missing = 1
      vim.g.gutentags_generate_on_write = 1
      vim.g.gutentags_ctags_extra_args = { "--python-kinds=+cfmvi" }
    end,
  },
} 