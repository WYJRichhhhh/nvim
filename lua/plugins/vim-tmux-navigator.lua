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
}

