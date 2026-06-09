-- 文件浏览器 / 目录树
return {
  -- https://github.com/nvim-tree/nvim-tree.lua
  'nvim-tree/nvim-tree.lua',
  dependencies = {
    -- https://github.com/nvim-tree/nvim-web-devicons
    'nvim-tree/nvim-web-devicons', -- 提供文件图标支持
  },
  opts = {
    actions = {
      open_file = {
        window_picker = {
          enable = true,
        },
        quit_on_open = false,
        resize_window = true,
      }
    },
    filters = {
      dotfiles = false,
    },
  },
  config = function(_, opts)
    -- 官方推荐：禁用内置 netrw 文件浏览器，避免与 nvim-tree 冲突
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    require("nvim-tree").setup(opts)
  end
}
