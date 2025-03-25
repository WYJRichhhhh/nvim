-- 修复 nvim-dap-ui 的 Invalid buffer id 错误
return {
  "rcarriga/nvim-dap-ui",
  dependencies = {
    "mfussenegger/nvim-dap",
  },
  config = function()
    -- 先确保插件已加载
    if not package.loaded["dapui"] then
      return
    end
    
    -- 修复 dapui.toggle() 中的错误
    local ok, dapui = pcall(require, "dapui")
    if not ok then
      return
    end
    
    -- 保存原始的 toggle 函数
    local original_toggle = dapui.toggle
    
    -- 替换为我们的安全版本
    dapui.toggle = function(...)
      local status, err = pcall(original_toggle, ...)
      if not status then
        vim.notify("DAP UI 切换失败: " .. tostring(err), vim.log.levels.WARN)
        -- 尝试重置 UI 状态
        vim.defer_fn(function()
          -- 尝试关闭所有可能处于不一致状态的 DAP UI 窗口
          pcall(function() 
            for _, win in pairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_is_valid(win) then
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.api.nvim_buf_is_valid(buf) then
                  local name = vim.api.nvim_buf_get_name(buf)
                  if name:match("DAP") then
                    vim.api.nvim_win_close(win, true)
                  end
                end
              end
            end
          end)
          
          -- 延迟后尝试重新打开
          vim.defer_fn(function()
            pcall(function() dapui.open() end)
          end, 200)
        end, 100)
      end
      return status
    end
    
    -- 修复 layout.lua 中的问题
    -- 猴子补丁 nvim_set_current_buf 调用
    local original_windows_layout = package.loaded["dapui.windows.layout"]
    if original_windows_layout then
      local original_open = original_windows_layout.WindowLayout.open
      
      original_windows_layout.WindowLayout.open = function(self)
        if self:is_open() then
          return
        end
        
        -- 使用 pcall 安全版本
        pcall(function()
          local cur_win = vim.api.nvim_get_current_win()
          for i, _ in pairs(self.win_states) do
            local get_buffer = self.open_index(i)
            local win_id = vim.api.nvim_get_current_win()
            
            -- 获取缓冲区并检查有效性
            local buffer = get_buffer()
            if buffer and vim.api.nvim_buf_is_valid(buffer) then
              vim.api.nvim_set_current_buf(buffer)
              self.opened_wins[i] = win_id
              self:_init_win_settings(win_id)
              self.win_bufs[win_id] = get_buffer
            else
              vim.notify("DAP UI 无法获取有效缓冲区", vim.log.levels.WARN)
            end
          end
          
          self:resize()
        end)
      end
    end
    
    vim.notify("已应用 DAP UI 补丁，修复无效缓冲区问题", vim.log.levels.INFO)
  end,
} 