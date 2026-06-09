-- 显示基于 LSP 的面包屑导航
return {
  -- https://github.com/utilyre/barbecue.nvim
  "utilyre/barbecue.nvim",
  name = "barbecue",
  version = "*",
  dependencies = {
  -- https://github.com/SmiteshP/nvim-navic
    "SmiteshP/nvim-navic",
  -- https://github.com/nvim-tree/nvim-web-devicons
    "nvim-tree/nvim-web-devicons", -- 可选依赖
  },
  opts = {
    -- 配置写在这里
  },
}

