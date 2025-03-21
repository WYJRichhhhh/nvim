-- Python 补全和智能提示增强
return {
  {
    -- 智能语法高亮和自动缩进
    "nvim-treesitter/nvim-treesitter",
    ft = "python",
    config = function()
      require("nvim-treesitter.configs").setup({
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        -- 增强的选择功能
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = "<nop>",
            node_decremental = "<bs>",
          },
        },
      })
    end,
  },
  {
    -- Python补全增强插件
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      -- Python API文档支持
      "hrsh7th/cmp-nvim-lsp-document-symbol",
      -- Python语言服务器补全
      "hrsh7th/cmp-nvim-lsp",
      -- Python模块路径补全
      "hrsh7th/cmp-path",
      -- Python缓冲区补全
      "hrsh7th/cmp-buffer",
      -- Python代码片段支持
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      -- Python docstring补全
      "hrsh7th/cmp-nvim-lsp-signature-help",
      -- Python标签补全
      "hrsh7th/cmp-cmdline",
      -- 更好的排序算法
      "lukas-reineke/cmp-under-comparator",
      -- 类型提示支持
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      -- 载入Python特定的代码片段
      require("luasnip.loaders.from_vscode").lazy_load({
        paths = { "./snippets/python" },
      })

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete({}),
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "nvim_lsp_signature_help", priority = 900 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),
        -- 高级UI功能
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
            show_labelDetails = true,
            -- Python特定图标
            symbol_map = {
              Class = "🐍 ",
              Function = "λ ",
              Method = "𝓜 ",
              Module = "📦 ",
              Variable = "𝒙 ",
              Property = "🏠 ",
              Keyword = "🔑 ",
            },
          }),
        },
        sorting = {
          comparators = {
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            require("cmp-under-comparator").under,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },
        experimental = {
          ghost_text = { hl_group = "CmpGhostText" },
        },
      })

      -- Python文件特定的命令行补全配置
      cmp.setup.filetype("python", {
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "nvim_lsp_signature_help", priority = 900 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),
      })
    end,
  },
  {
    -- Python导入自动处理
    "mhartington/formatter.nvim",
    ft = "python",
    config = function()
      require("formatter").setup({
        filetype = {
          python = {
            -- 使用isort优化导入
            function()
              return {
                exe = "isort",
                args = { "--profile", "black", "-" },
                stdin = true,
              }
            end,
            -- 使用autoflake删除未使用的导入
            function()
              return {
                exe = "autoflake",
                args = {
                  "--remove-all-unused-imports",
                  "--remove-unused-variables",
                  "-",
                },
                stdin = true,
              }
            end,
          },
        },
      })
      -- 设置自动格式化导入命令
      vim.api.nvim_create_user_command("PythonFixImports", function()
        vim.cmd("Format")
      end, {})
      -- 快捷键
      vim.keymap.set("n", "<leader>pi", ":PythonFixImports<CR>", { desc = "修复Python导入" })
    end,
  },
  {
    -- LSP增强功能
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lspsaga").setup({
        lightbulb = {
          enable = true,
          sign = true,
          virtual_text = true,
        },
        code_action = {
          show_server_name = true,
          extend_gitsigns = true,
        },
        -- 文档和引用浮动窗口设置
        ui = {
          border = "rounded",
          code_action = "💡",
        },
        -- 悬停窗口设置
        hover = {
          max_width = 0.6,
          open_link = "gx",
          open_browser = "!chrome",
        },
        -- 定义/引用查看器
        definition = {
          width = 0.6,
          height = 0.4,
        },
        -- 查找引用窗口设置
        finder = {
          default = "ref+def+imp",
          layout = "float",
        },
        -- Python特定键映射
        symbol_in_winbar = {
          enable = true,
          separator = " > ",
          hide_keyword = true,
          show_file = true,
          folder_level = 1,
        },
      })
      
      -- Python特定的LSP快捷键
      vim.keymap.set("n", "gh", "<cmd>Lspsaga hover_doc<CR>", { desc = "查看文档" })
      vim.keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<CR>", { desc = "转到定义" })
      vim.keymap.set("n", "gr", "<cmd>Lspsaga finder<CR>", { desc = "查找引用" })
      vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc = "代码操作" })
      vim.keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", { desc = "重命名" })
      vim.keymap.set("n", "<leader>cd", "<cmd>Lspsaga show_cursor_diagnostics<CR>", { desc = "光标诊断" })
    end,
  },
  {
    -- 类型提示与错误高亮
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle<CR>", desc = "切换诊断窗口" },
      { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<CR>", desc = "工作区诊断" },
      { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<CR>", desc = "文档诊断" },
    },
    config = function()
      require("trouble").setup({
        position = "bottom",
        icons = true,
        auto_open = false,
        auto_close = false,
        use_diagnostic_signs = true,
        -- 自动将行分组
        group = true,
        padding = true,
      })
    end,
  },
} 