-- Debugging Support
return {
  -- https://github.com/rcarriga/nvim-dap-ui
  'rcarriga/nvim-dap-ui',
  event = 'VeryLazy',
  dependencies = {
    -- https://github.com/mfussenegger/nvim-dap
    'mfussenegger/nvim-dap',
    -- https://github.com/theHamsta/nvim-dap-virtual-text
    'theHamsta/nvim-dap-virtual-text', -- inline variable text while debugging
    -- https://github.com/nvim-telescope/telescope-dap.nvim
    'nvim-telescope/telescope-dap.nvim', -- telescope integration with dap
    "nvim-neotest/nvim-nio",
  },
  opts = {
    controls = {
      element = "repl",
      enabled = false,
      icons = {
        disconnect = "",
        pause = "",
        play = "",
        run_last = "",
        step_back = "",
        step_into = "",
        step_out = "",
        step_over = "",
        terminate = ""
      }
    },
    element_mappings = {},
    expand_lines = true,
    floating = {
      border = "single",
      mappings = {
        close = { "q", "<Esc>" }
      }
    },
    force_buffers = true,
    icons = {
      collapsed = "",
      current_frame = "",
      expanded = ""
    },
    layouts = {
      {
        elements = {
          {
            id = "scopes",
            size = 0.50
          },
          {
            id = "stacks",
            size = 0.30
          },
          {
            id = "watches",
            size = 0.10
          },
          {
            id = "breakpoints",
            size = 0.10
          }
        },
        size = 40,
        position = "left", -- Can be "left" or "right"
      },
      {
        elements = {
          "repl",
          "console",
        },
        size = 10,
        position = "bottom", -- Can be "bottom" or "top"
      }
    },
    mappings = {
      edit = "e",
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "d",
      repl = "r",
      toggle = "t"
    },
    render = {
      indent = 1,
      max_value_lines = 100
    }
  },
  config = function (_, opts)
    local dap, dapui = require("dap"), require("dapui")
    
    -- 改进 DAP UI 外观配置
    dapui.setup({
      icons = {
        expanded = "▾",
        collapsed = "▸",
        current_frame = "→",
      },
      mappings = {
        -- 使用鼠标
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
        toggle = "t",
      },
      -- 改进布局配置
      layouts = {
        {
          -- 左侧面板
          elements = {
            -- 优先显示断点和堆栈
            { id = "breakpoints", size = 0.20 },
            { id = "stacks", size = 0.20 },
            { id = "watches", size = 0.25 },
            { id = "scopes", size = 0.35 },
          },
          size = 0.25,  -- 宽度为25%
          position = "left",
        },
        {
          -- 底部面板 - 调整优先级，把 console 放在更显眼的位置
          elements = {
            { id = "console", size = 0.75 },  -- 增大 console 窗口
            { id = "repl", size = 0.25 },
          },
          size = 0.30,  -- 增加高度
          position = "bottom",
        },
      },
      -- 浮动窗口配置
      floating = {
        max_height = nil,
        max_width = nil,
        border = "double",  -- 双线边框更明显
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      windows = {
        indent = 1,  -- 缩进增加更好的视觉区分
      },
      render = {
        max_type_length = nil,  -- 完整显示类型
        max_value_lines = 100,  -- 允许显示更多行
      },
      -- 元素样式配置
      element_mappings = {},
      expand_lines = true,
      force_buffers = true,
      
      -- 元素标题
      element_titles = {
        scopes = { "🔍 作用域变量" },
        breakpoints = { "⚡ 断点列表" },
        stacks = { "📚 调用堆栈" },
        watches = { "👁 监视表达式" },
        console = { "📋 控制台输出" },
        repl = { "💻 交互命令行" },
      },
      
      -- 启用明显的窗口标题
      ui = {
        auto_open = true,
        notify = {
          threshold = vim.log.levels.INFO,
        },
        border = "double",  -- 统一使用双线边框
        title = true,  -- 显示标题
        winblend = 0,  -- 不透明度为0，完全不透明
        title_pos = "center",  -- 标题居中
      },
      
      -- 启用控件
      controls = {
        enabled = true,
        element = "console",  -- 将控件放在 console 元素中
        icons = {
          pause = "⏸ 暂停",
          play = "▶ 继续",
          step_into = "⏎ 进入",
          step_over = "↷ 跳过",
          step_out = "↑ 跳出",
          step_back = "↶ 后退",
          run_last = "↻ 重运行",
          terminate = "□ 终止",
        },
      },
    })
    
    -- 自动打开/关闭 DAP UI
    dap.listeners.after.event_initialized["dapui_config"] = function()
      -- 使用 pcall 安全地调用 dapui.open
      local status, err = pcall(function()
        -- 先检查窗口是否有效，避免无效缓冲区错误
        for _, win in pairs(vim.api.nvim_list_wins()) do
          if not vim.api.nvim_win_is_valid(win) then
            return
          end
          local buf = vim.api.nvim_win_get_buf(win)
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end
        end
        
        dapui.open()
      end)
      
      if not status then
        vim.notify("DAP UI 打开失败: " .. tostring(err), vim.log.levels.WARN)
        -- 尝试延迟打开，给 DAP 会话更多初始化时间
        vim.defer_fn(function()
          pcall(dapui.open)
        end, 300)
      end
      
      -- 确保控制台窗口出现在前面 (也使用 pcall 保护)
      vim.defer_fn(function()
        pcall(function()
          vim.cmd("wincmd j") -- 跳到底部窗口
          
          -- 尝试找到控制台窗口并聚焦
          for _, win in pairs(vim.api.nvim_list_wins()) do
            if win > 0 and vim.api.nvim_win_is_valid(win) then
              local buf = vim.api.nvim_win_get_buf(win)
              if buf > 0 and vim.api.nvim_buf_is_valid(buf) then
                local name = vim.api.nvim_buf_get_name(buf)
                if name:match("DAP") and name:match("Console") then
                  vim.api.nvim_set_current_win(win)
                  break
                end
              end
            end
          end
          
          -- 运行一个初始化命令，通知用户调试已开始
          vim.cmd([[
            echohl Special
            echo "调试已启动！控制台日志将在此窗口显示..."
            echohl None
          ]])
        end)
      end, 400)
    end
    
    dap.listeners.before.event_terminated["dapui_config"] = function()
      pcall(dapui.close)
    end
    
    dap.listeners.before.event_exited["dapui_config"] = function()
      pcall(dapui.close)
    end
    
    -- 添加自定义高亮组以改善视觉效果
    vim.api.nvim_exec([[
      highlight DapUIPlayPause guifg=#50FA7B gui=bold
      highlight DapUIRestart guifg=#50FA7B gui=bold
      highlight DapUIStop guifg=#FF5555 gui=bold
      highlight DapUIStepOver guifg=#BD93F9 gui=bold
      highlight DapUIStepInto guifg=#8BE9FD gui=bold
      highlight DapUIStepOut guifg=#FF79C6 gui=bold
      highlight DapUIStepBack guifg=#FFB86C gui=bold
      highlight DapUIType guifg=#8BE9FD
      highlight DapUIVariable guifg=#F8F8F2
      highlight DapUIValue guifg=#50FA7B
      highlight DapUIFrameName guifg=#F8F8F2
      highlight DapUIThread guifg=#FF79C6
      highlight DapUIWatchesEmpty guifg=#FF5555 gui=italic
      highlight DapUIWatchesValue guifg=#50FA7B
      highlight DapUIWatchesError guifg=#FF5555
      highlight DapUIScope guifg=#BD93F9
      highlight DapUIBreakpointsPath guifg=#FF79C6
      highlight DapUIBreakpointsInfo guifg=#8BE9FD
      highlight DapUIBreakpointsCurrentLine guifg=#50FA7B gui=bold
      highlight DapUIModifiedValue guifg=#FFB86C gui=bold
      highlight DapUINormalFloat guibg=#282A36 guifg=#F8F8F2
      highlight link DapUIFloatBorder FloatBorder
      
      " 添加窗口边界和标题的高亮
      highlight DapUITitle guifg=#BD93F9 gui=bold
      highlight DapUIBorder guifg=#6272A4
      highlight DapUIEndofBuffer guifg=#6272A4
      highlight DapUIWinSelect guifg=#FFB86C gui=bold
      highlight DapUILineNumber guifg=#6272A4
      highlight DapUISource guifg=#50FA7B
      highlight DapUIDecoration guifg=#BD93F9
    ]], false)
    
    -- 设置更明显的窗口分隔线
    vim.cmd([[
      set fillchars+=vert:│
      highlight WinSeparator guifg=#BD93F9 gui=bold
    ]])
    
    -- 创建帮助命令，显示 DAP UI 使用指南
    vim.api.nvim_create_user_command("DapUIHelp", function()
      local help_text = [[
## DAP UI 使用指南

### 窗口说明
- 🔍 作用域变量 - 显示当前上下文中的变量
- ⚡ 断点列表 - 显示所有设置的断点
- 📚 调用堆栈 - 显示函数调用层次
- 👁 监视表达式 - 显示用户添加的监视变量
- 📋 控制台输出 - 显示程序输出和日志
- 💻 交互命令行 - 可执行表达式的命令行

### 基本操作
- <leader>dd - 调试当前文件
- <leader>bb - 切换断点
- <leader>eb - 设置条件断点
- <leader>raB - 清除所有断点

### 调试控制
- <leader>dc - 继续执行
- <leader>do - 单步跳过 (Step Over)
- <leader>di - 单步进入 (Step Into)
- <leader>ds - 单步跳出 (Step Out)
- <leader>dx - 终止调试

### 视图操作
- <leader>pp - 显示/隐藏调试界面
- <leader>dr - 打开 REPL
- <leader>dh - 显示此帮助文档
- <leader>df - 聚焦到控制台窗口 (查看日志输出)
- <leader>dt - 显示调试状态和帮助

### 面板操作
- 在面板中按 <CR> 或双击展开/折叠项目
- o - 打开文件
- d - 删除 (如观察变量)
- e - 编辑 (如观察表达式)
- r - 在 REPL 中打开
- t - 切换

### 监视变量
- 在变量面板中，选中变量后按 d 添加到监视列表
- 在监视面板中，按 + 添加新的监视表达式
      ]]
      
      -- 在拆分窗口中显示帮助
      vim.cmd("40vsplit")
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(help_text, "\n"))
      vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
      vim.api.nvim_win_set_buf(0, buf)
      vim.api.nvim_win_set_option(0, "wrap", true)
      vim.api.nvim_win_set_option(0, "cursorline", true)
      
      -- 按 q 关闭帮助窗口
      vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
    end, {})
    
    -- 为每个窗口添加标题的函数
    local function setup_dap_window_titles()
      vim.defer_fn(function()
        -- 查找所有 DAP UI 窗口并添加标题
        for _, win in pairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local buf_name = vim.api.nvim_buf_get_name(buf)
          
          if buf_name:match("DAP") then
            local title = "调试窗口"
            
            if buf_name:match("Scopes") then
              title = "🔍 作用域变量"
            elseif buf_name:match("Breakpoints") then
              title = "⚡ 断点列表"
            elseif buf_name:match("Stacks") then
              title = "📚 调用堆栈"
            elseif buf_name:match("Watches") then
              title = "👁 监视表达式"
            elseif buf_name:match("Console") then
              title = "📋 控制台输出"
            elseif buf_name:match("REPL") then
              title = "💻 交互命令行"
            end
            
            -- 设置窗口标题
            vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:DapUIBorder")
            vim.api.nvim_win_set_option(win, "title", title)
            vim.api.nvim_win_set_option(win, "titlestring", title)
          end
        end
      end, 100)
    end
    
    -- DAP UI 打开时设置窗口标题
    vim.api.nvim_create_autocmd("User", {
      pattern = "DapUIOpened",
      callback = setup_dap_window_titles
    })
    
    -- 映射打开帮助的快捷键
    vim.keymap.set("n", "<leader>dh", ":DapUIHelp<CR>", { desc = "显示调试帮助" })
    
    -- 创建自定义命令，聚焦到控制台窗口
    vim.api.nvim_create_user_command("DapUIFocusConsole", function()
      -- 使用 pcall 处理错误
      local status, err = pcall(function()
        -- 检查 DAP 是否运行
        if not dap.session() then
          vim.notify("调试会话未启动，请先使用 <leader>dd 启动调试", vim.log.levels.WARN)
          return
        end
        
        -- 确保 DAP UI 是打开的
        if not dapui.is_open() then
          local open_status, open_err = pcall(dapui.open)
          if not open_status then
            vim.notify("无法打开 DAP UI: " .. tostring(open_err), vim.log.levels.WARN)
            return
          end
          
          vim.defer_fn(function()
            vim.cmd("redraw")
          end, 100)
        end
        
        -- 尝试找到控制台窗口并聚焦
        vim.defer_fn(function()
          local found = false
          for _, win in pairs(vim.api.nvim_list_wins()) do
            if win > 0 and vim.api.nvim_win_is_valid(win) then
              local buf = vim.api.nvim_win_get_buf(win)
              if buf > 0 and vim.api.nvim_buf_is_valid(buf) then
                local name = vim.api.nvim_buf_get_name(buf)
                if name:match("DAP") and (name:match("Console") or name:match("console")) then
                  vim.api.nvim_set_current_win(win)
                  vim.notify("已聚焦到控制台窗口", vim.log.levels.INFO)
                  found = true
                  break
                end
              end
            end
          end
          
          if not found then
            -- 尝试找底部窗口
            pcall(function()
              vim.cmd("wincmd j") -- 移动到底部窗口
              local win = vim.api.nvim_get_current_win()
              if win > 0 and vim.api.nvim_win_is_valid(win) then
                local buf = vim.api.nvim_win_get_buf(win)
                if buf > 0 and vim.api.nvim_buf_is_valid(buf) then
                  local name = vim.api.nvim_buf_get_name(buf)
                  
                  if name:match("DAP") then
                    vim.notify("找到 DAP 窗口，但无法确认是否为控制台", vim.log.levels.INFO)
                  else
                    vim.notify("未找到控制台窗口。请确保调试会话已启动并且 DAP UI 已打开", vim.log.levels.WARN)
                    
                    -- 提供帮助信息
                    vim.defer_fn(function()
                      vim.cmd("echo '提示: 请先设置断点并使用 <leader>dd 启动调试，然后再尝试查看控制台'")
                    end, 1000)
                  end
                end
              end
            end)
          end
        end, 200)
      end)
      
      if not status then
        vim.notify("无法聚焦到控制台: " .. tostring(err), vim.log.levels.ERROR)
      end
    end, {})
    
    -- 添加快捷键
    vim.keymap.set("n", "<leader>df", ":DapUIFocusConsole<CR>", { desc = "聚焦到控制台窗口" })
    
    -- 创建调试助手函数，显示当前状态
    vim.api.nvim_create_user_command("DapStatus", function()
      -- 使用 pcall 处理可能的错误
      pcall(function()
        -- 创建状态窗口
        vim.cmd("botright split")
        local status_win = vim.api.nvim_get_current_win()
        
        -- 检查窗口是否有效
        if not vim.api.nvim_win_is_valid(status_win) then
          vim.notify("无法创建状态窗口", vim.log.levels.WARN)
          return
        end
        
        local status_buf = vim.api.nvim_create_buf(false, true)
        
        -- 检查缓冲区是否有效
        if not vim.api.nvim_buf_is_valid(status_buf) then
          vim.notify("无法创建状态缓冲区", vim.log.levels.WARN)
          return
        end
        
        vim.api.nvim_win_set_buf(status_win, status_buf)
        vim.api.nvim_win_set_height(status_win, 10)
        
        -- 设置窗口选项
        pcall(function()
          vim.api.nvim_win_set_option(status_win, "wrap", true)
          vim.api.nvim_win_set_option(status_win, "cursorline", true)
          vim.api.nvim_buf_set_option(status_buf, "modifiable", true)
          vim.api.nvim_buf_set_option(status_buf, "filetype", "markdown")
        end)
        
        -- 准备状态信息
        local lines = {
          "# 调试状态检查",
          "",
        }
        
        -- 检查调试会话
        if dap.session() then
          table.insert(lines, "✅ **调试会话已启动**")
          
          -- 检查断点
          local breakpoints = require("dap.breakpoints").get()
          local bp_count = 0
          for _, bps in pairs(breakpoints) do
            bp_count = bp_count + #bps
          end
          
          if bp_count > 0 then
            table.insert(lines, string.format("✅ **已设置 %d 个断点**", bp_count))
          else
            table.insert(lines, "❌ **未设置任何断点** - 请使用 <leader>bb 设置断点")
          end
          
          -- 检查程序状态
          local status = dap.status()
          table.insert(lines, string.format("📊 **程序状态:** %s", status))
          
          -- 添加操作提示
          table.insert(lines, "")
          table.insert(lines, "## 调试操作")
          table.insert(lines, "- 使用 `<leader>dc` 继续执行")
          table.insert(lines, "- 使用 `<leader>do` 单步跳过")
          table.insert(lines, "- 使用 `<leader>di` 单步进入")
          table.insert(lines, "- 使用 `<leader>ds` 单步跳出")
          table.insert(lines, "- 使用 `<leader>dx` 终止调试")
          table.insert(lines, "- 使用 `<leader>df` 查看控制台输出")
        else
          table.insert(lines, "❌ **调试会话未启动**")
          table.insert(lines, "")
          table.insert(lines, "## 开始调试")
          table.insert(lines, "1. 首先使用 `<leader>bb` 在关键代码处设置断点")
          table.insert(lines, "2. 使用 `<leader>dd` 启动调试器")
          table.insert(lines, "")
          table.insert(lines, "## 调试小技巧")
          table.insert(lines, "- 初次调试时，在程序入口处设置断点很重要")
          table.insert(lines, "- 对于异步程序，建议在 async 函数的开头设置断点")
          table.insert(lines, "- 如果程序立即结束，可能需要在主循环或关键函数中设置断点")
        end
        
        -- 添加关闭提示
        table.insert(lines, "")
        table.insert(lines, "按 `q` 关闭此窗口")
        
        -- 设置内容 (使用 pcall 保护以避免错误)
        pcall(function()
          if vim.api.nvim_buf_is_valid(status_buf) then
            vim.api.nvim_buf_set_lines(status_buf, 0, -1, false, lines)
            vim.api.nvim_buf_set_option(status_buf, "modifiable", false)
            
            -- 设置快捷键关闭窗口
            vim.api.nvim_buf_set_keymap(status_buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
          end
        end)
      end)
    end, {})
    
    -- 添加状态查看快捷键
    vim.keymap.set("n", "<leader>dt", ":DapStatus<CR>", { desc = "显示调试状态" })
  end
}

