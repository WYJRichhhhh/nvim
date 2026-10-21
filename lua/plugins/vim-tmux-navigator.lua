-- 用同一套 vim 键位在 nvim 与 tmux 的窗口/窗格间无缝跳转
return {
  -- https://github.com/christoomey/vim-tmux-navigator
  'christoomey/vim-tmux-navigator',
  -- 只有在 tmux 中运行时才加载此插件
  event = function()
    if vim.fn.exists("$TMUX") == 1 then
      return "VeryLazy"
    end
  end,
  config = function()
    local directions = { h = "Left", j = "Down", k = "Up", l = "Right" }
    for key, direction in pairs(directions) do
      local lhs = "<C-" .. key .. ">"
      vim.keymap.set("t", lhs, function()
        -- Agent TUI 使用原生按键，例如 Codex 的 Ctrl-j 换行。
        if vim.bo.filetype == "agent_terminal" or vim.bo.filetype == "fzf" then
          return lhs
        end
        -- 其他终端先真正退出终端输入模式，再执行窗口导航命令。
        return "<C-\\><C-n><cmd>TmuxNavigate" .. direction .. "<CR>"
      end, { expr = true, silent = true, desc = "终端导航（Agent 保留原生按键）" })
    end
  end,
}

