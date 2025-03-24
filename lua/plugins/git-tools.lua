-- Git工具集成配置
return {
  {
    -- 行内Git变更指示器
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signcolumn = true,  -- 显示在符号列
      numhl = false,      -- 不高亮行号
      linehl = false,     -- 不高亮整行
      word_diff = false,  -- 不在行内显示文字级差异
      watch_gitdir = {
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true,
      current_line_blame = true, -- 显示当前行的提交信息
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 在行尾显示
        delay = 500,          -- 延迟显示时间
      },
      current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
      update_debounce = 100,  -- 延迟更新，提高性能
      -- 集成设置
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- 导航操作
        map("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "下一个Git变更"})

        map("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "上一个Git变更"})

        -- 操作
        map("n", "<leader>gs", gs.stage_hunk, { desc = "暂存Git变更块" })
        map("n", "<leader>gr", gs.reset_hunk, { desc = "重置Git变更块" })
        map("v", "<leader>gs", function() gs.stage_hunk {vim.fn.line("."), vim.fn.line("v")} end, { desc = "暂存选中区域" })
        map("v", "<leader>gr", function() gs.reset_hunk {vim.fn.line("."), vim.fn.line("v")} end, { desc = "重置选中区域" })
        map("n", "<leader>gS", gs.stage_buffer, { desc = "暂存整个缓冲区" })
        map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "撤销暂存变更块" })
        map("n", "<leader>gR", gs.reset_buffer, { desc = "重置整个缓冲区" })
        map("n", "<leader>gp", gs.preview_hunk, { desc = "预览Git变更块" })
        map("n", "<leader>gb", function() gs.blame_line{full=true} end, { desc = "查看行归属信息" })
        map("n", "<leader>gtb", gs.toggle_current_line_blame, { desc = "切换行归属信息" })
        map("n", "<leader>gd", gs.diffthis, { desc = "与索引比较差异" })
        map("n", "<leader>gD", function() gs.diffthis("~") end, { desc = "与HEAD比较差异" })
        map("n", "<leader>gtd", gs.toggle_deleted, { desc = "切换删除行显示" })

        -- 文本对象
        map({"o", "x"}, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "选择Git变更块" })
      end,
    },
  },
  {
    -- Git差异查看器
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<CR>", desc = "打开差异查看器" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<CR>", desc = "查看文件历史" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<CR>", desc = "查看当前文件历史" },
    },
    opts = {
      diff_binaries = false,  -- 不比较二进制文件
      enhanced_diff_hl = true, -- 使用增强的差异高亮
      use_icons = true,        -- 使用图标
      icons = {               -- 使用自定义图标
        folder_closed = "",
        folder_open = "",
      },
      signs = {
        fold_closed = "",
        fold_open = "",
      },
      view = {
        default = {
          layout = "diff2_horizontal",  -- 默认水平布局
          winbar_info = false,          -- 不在窗口栏显示信息
        },
        merge_tool = {
          layout = "diff3_horizontal",  -- 合并工具使用3窗口水平布局
          disable_diagnostics = true,   -- 禁用合并视图中的诊断
        },
        file_history = {
          layout = "diff2_horizontal",  -- 文件历史使用水平布局
        },
      },
      file_panel = {
        listing_style = "tree",         -- 使用树形列表
        tree_options = {                -- 树形选项
          flatten_dirs = true,          -- 扁平化目录
          folder_statuses = "only_folded", -- 只显示折叠的文件夹状态
        },
        win_config = {                  -- 窗口配置
          position = "left",
          width = 35,
        },
      },
      file_history_panel = {
        win_config = {
          position = "bottom",
          height = 16,
        },
      },
      commit_log_panel = {
        win_config = {},
      },
      default_args = {
        DiffviewOpen = {},
        DiffviewFileHistory = {},
      },
      hooks = {},
      keymaps = {
        disable_defaults = false,      -- 不禁用默认键映射
      },
    },
  },
  {
    -- Magit风格的Git客户端
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<CR>", desc = "打开Neogit" },
    },
    opts = {
      integrations = {
        diffview = true,     -- 使用diffview.nvim集成
        telescope = true,    -- 使用telescope集成
      },
      disable_signs = false, -- 启用标志
      disable_context_highlighting = false, -- 启用上下文高亮
      disable_commit_confirmation = false,  -- 需要提交确认
      auto_refresh = true,   -- 自动刷新
      disable_builtin_notifications = false, -- 使用内置通知
      use_magit_keybindings = false, -- 不使用Magit键绑定
      kind = "tab",          -- 使用标签页显示
      commit_popup = {
        kind = "split",      -- 提交弹窗使用分割窗口
      },
      popup = {
        kind = "split",      -- 弹窗使用分割窗口
      },
      signs = {
        section = { "", "" }, -- 节标志
        item = { "", "" },    -- 项标志
        hunk = { "", "" },    -- 变更块标志
      },
      -- 推荐的设置，优化体验
      sections = {
        untracked = {
          folded = false,    -- 默认展开未跟踪文件
        },
        unstaged = {
          folded = false,    -- 默认展开未暂存文件
        },
        staged = {
          folded = false,    -- 默认展开已暂存文件
        },
        stashes = {
          folded = true,     -- 默认折叠贮藏
        },
        unpulled = {
          folded = true,     -- 默认折叠未拉取
          hidden = false,    -- 不隐藏未拉取
        },
        unmerged = {
          folded = false,    -- 默认展开未合并
          hidden = false,    -- 不隐藏未合并
        },
        recent = {
          folded = true,     -- 默认折叠最近更改
        },
      },
    },
  },
  {
    -- 浏览Git版本库内容
    "rbong/vim-flog",
    lazy = true,
    cmd = { "Flog", "Flogsplit" },
    dependencies = {
      "tpope/vim-fugitive",
    },
    keys = {
      { "<leader>gl", "<cmd>Flog<CR>", desc = "查看Git日志(Flog)" },
    },
  },
  {
    -- 基础Git集成 (必要依赖)
    "tpope/vim-fugitive",
    cmd = {
      "Git",
      "Gstatus",
      "Gblame",
      "Gpush",
      "Gpull",
      "Gvdiffsplit"
    },
    keys = {
      { "<leader>gB", "<cmd>Git blame<CR>", desc = "Git blame" },
      { "<leader>gc", "<cmd>Git commit<CR>", desc = "Git commit" },
      { "<leader>gP", "<cmd>Git push<CR>", desc = "Git push" },
      { "<leader>gL", "<cmd>Git pull<CR>", desc = "Git pull" },
    },
  },
} 