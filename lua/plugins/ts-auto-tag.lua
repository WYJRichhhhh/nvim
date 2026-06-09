return {
  -- https://github.com/williamboman/nvim-lsp-ts-utils
  'windwp/nvim-ts-autotag',
  config = function()
    require('nvim-ts-autotag').setup({
      opts = {
        -- 默认值
        enable_close = true,      -- 自动闭合标签
        enable_rename = true,     -- 成对标签自动重命名
        enable_close_on_slash = false -- 输入末尾的 </ 时自动闭合
      },
      -- 也可按文件类型单独覆盖，优先级高于上面的全局配置。
      -- 默认为空；当某项全局 "opts" 设置在特定文件类型下表现不佳时很有用。
      -- per_filetype = {
      --   ["html"] = {
      --     enable_close = false
      --   }
      -- }
    })
  end
}
