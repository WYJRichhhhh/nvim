-- Python 格式化工具
return {
  -- https://github.com/psf/black
  'psf/black',
  ft = 'python',
  config =function ()
    -- 保存时自动格式化当前文件缓冲区
    vim.api.nvim_create_autocmd({ "BufWritePre" }, {
      pattern = "*.py",
      callback = function()
        vim.cmd("Black")
      end,
    })
  end
}
