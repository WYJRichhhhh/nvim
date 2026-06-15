-- Git工具集成配置

-- diffview / Flog 这类「重界面」各自独占一个 tab、把多个窗口当成一个整体打开，
-- 却不自带关闭键，于是只能用 <leader>qq 逐个关 buffer，很笨。这里给它们统一加
-- 「开/关切换」：同一个键按一下开、再按一下整体关掉。
-- （gg=Neogit 自带 q、gB=fugitive blame 自带 gq，已能整体关，无需在此处理。）

-- 切换 diffview：lib.views 里有任意视图(差异/文件历史，含 Neogit 唤起的)就全部关掉，
-- 否则按传入命令打开。
-- 关闭不能用 :DiffviewClose——它只关「当前 tab 的那个 view」(内部走 get_current_view，
-- 只认 view.tabpage==当前tab)。Neogit 唤起的 diff 在别的 tab，你按键时焦点不在那里，
-- DiffviewClose 就成了空操作、关不掉。所以这里直接遍历 lib.views 逐个 view:close()，
-- 对原生和 Neogit 唤起的 view 一视同仁。倒序遍历因 close 会从该表移除元素。
local function diffview_toggle(open_cmd)
  return function()
    local views = require("diffview.lib").views
    if next(views) == nil then
      vim.cmd(open_cmd)
    else
      for i = #views, 1, -1 do
        views[i]:close()
      end
    end
  end
end

-- 切换 Flog：扫到已打开的 floggraph 窗口就关掉它所在的 tab(Flog 独占 tab)，否则开 Flog。
local function flog_toggle()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "floggraph" then
      vim.api.nvim_win_call(win, function() vim.cmd("tabclose") end)
      return
    end
  end
  vim.cmd("Flog")
end

-- worktree 选择器(<leader>gw):列出本仓库所有 worktree,选中后用 Neogit 打开「那个 worktree
-- 目录」的状态缓冲区。
--
-- 解决的痛点:用 git worktree 时主 nvim 停在 dev/test 分支的主 worktree 不动,而 claude agent
-- 在别处的 worktree 开 feat/xxx 做开发。过去想看那个分支改了啥、或帮它提交,只能:先开 shell
-- 进到那个目录 `add . && commit`,再回 nvim 用 log 看 commit 改了啥——因为 worktree 检出的分支
-- 不能在主 worktree 里 checkout,neogit 又默认只盯当前 worktree。
--
-- 而 neogit 的 open 支持 `cwd=`,内部按该目录单独建 repository 实例(repository.instance(cwd)),
-- 把整个状态缓冲区钉在那个 worktree 上。于是无需 checkout、无需开 shell:选中 worktree 即在它的
-- 状态缓冲区里直接看未提交的 diff(<Tab> 展开)、`s` 暂存、`c c` 提交,全程不离开当前 nvim。
local function neogit_worktree_picker()
  -- 从「当前文件所在目录」推断仓库,而不是 nvim 的 getcwd——这样在任意 buffer 里触发都落到对的仓库。
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.uv.cwd()
  end

  local out = vim.fn.systemlist({ "git", "-C", dir, "worktree", "list", "--porcelain" })
  if vim.v.shell_error ~= 0 then
    vim.notify("不在 git 仓库内,或 git worktree 不可用", vim.log.levels.WARN)
    return
  end

  -- 解析 porcelain 输出:每条记录以 "worktree <path>" 起头,后跟 HEAD/branch 行(裸仓库或游离头则没有
  -- branch,分别标成 (bare)/(detached))。逐行累进到 cur 这条记录上。
  local worktrees = {}
  local cur
  for _, line in ipairs(out) do
    local path = line:match("^worktree (.+)$")
    if path then
      cur = { path = path }
      table.insert(worktrees, cur)
    elseif cur then
      local br = line:match("^branch refs/heads/(.+)$")
      if br then
        cur.branch = br
      elseif line == "detached" then
        cur.branch = "(detached)"
      elseif line == "bare" then
        cur.branch = "(bare)"
      end
    end
  end

  -- 按最长分支名对齐,让「分支名 + 路径」两列扫一眼就分得清。
  local width = 0
  for _, w in ipairs(worktrees) do
    width = math.max(width, vim.fn.strdisplaywidth(w.branch or ""))
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Git Worktrees (回车: 用 Neogit 打开其状态)",
    finder = finders.new_table({
      results = worktrees,
      entry_maker = function(w)
        local branch = w.branch or "(unknown)"
        return {
          value = w,
          display = string.format("%-" .. width .. "s  %s", branch, w.path),
          ordinal = branch .. " " .. w.path,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel and sel.value then
          require("neogit").open({ cwd = sel.value.path, kind = "tab" })
        end
      end)
      return true
    end,
  }):find()
end

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
      { "<leader>gv", diffview_toggle("DiffviewOpen"), desc = "切换差异查看器" },
      -- 不传参 = 当前文件历史，Diffview 自己回溯真实 git 路径，
      -- 即使人在 gitsigns 的索引/diff 虚拟 buffer 里也不会崩（不像 % 会展开成假路径）
      { "<leader>gh", diffview_toggle("DiffviewFileHistory"), desc = "切换当前文件历史" },
      -- 传 . = 整个项目（仓库根）历史
      { "<leader>gH", diffview_toggle("DiffviewFileHistory ."), desc = "切换整个项目历史" },
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
      -- 选某个 worktree,直接看它(常是 claude agent 在 feat/xxx 上)的未提交改动、就地提交,
      -- 无需 checkout、无需开 shell。详见 neogit_worktree_picker 上方注释。
      { "<leader>gw", neogit_worktree_picker, desc = "选 worktree 看其改动(Neogit)" },
    },
    config = function(_, opts)
      -- 修复 neogit 上游 bug：被「其它 worktree」检出的分支在 diff/branch popup 里消失。
      -- 根因：neogit 的 get_local_branches 靠解析 `git branch` 的文本，正则写死成
      -- "^  (.+)"（恰好两个空格开头）。但 git 对被其它 worktree 占用的分支用的是 "+ "
      -- 前缀（不是空格），于是这些分支被整体丢弃——`d r`(diff range)、`b`(branch popup)
      -- 的候选里既看不到也搜不到。而 `l o`(log other)走的是 for-each-ref，不受影响。
      -- 这里把 get_local_branches 改为同样复用 for-each-ref（refs.list_local_branches），
      -- 它按 refname 枚举、不看 worktree 占用前缀，从源头绕开解析缺陷。
      local branch = require("neogit.lib.git.branch")
      branch.get_local_branches = function(include_current)
        local locals = require("neogit.lib.git.refs").list_local_branches()
        if include_current then
          return locals
        end
        -- include_current=false 时按原语义排除当前分支
        local current = branch.current()
        return vim.tbl_filter(function(b)
          return b ~= current
        end, locals)
      end

      require("neogit").setup(opts)
    end,
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
      { "<leader>gl", flog_toggle, desc = "切换Git日志(Flog)" },
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
      -- push/pull 走 Neogit 控制台（<leader>gg）完成，这里不再单独留键位
    },
  },
} 