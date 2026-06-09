-- Git Blame
return {
  -- https://github.com/f-person/git-blame.nvim
  'f-person/git-blame.nvim',
  event = 'VeryLazy',
  opts = {
    enabled = false, -- 默认关闭，仅在按键触发时启用
    date_format = '%m/%d/%y %H:%M:%S', -- 更简洁的日期格式
  }
}

