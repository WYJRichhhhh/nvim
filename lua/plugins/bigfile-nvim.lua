-- 提升编辑大文件时的性能
return {
  -- https://github.com/LunarVim/bigfile.nvim
  'LunarVim/bigfile.nvim',
  event = 'BufReadPre',
  opts = {
    filesize = 2, -- 触发阈值（单位 MiB），插件会把文件大小就近取整到 MiB 比较
  },
  config = function (_, opts)
    require('bigfile').setup(opts)
  end
}
