return {
  "nvim-neotest/neotest",
  enabled = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-neotest/neotest-python",
  },
  config = function()
    -- 保留配置，以备将来需要时重新启用
    local neotest = require("neotest")
    
    neotest.setup({
      adapters = {
        require("neotest-python")({
          dap = { justMyCode = false },
          runner = "pytest",
          pytest = {
            args = {
              "--no-header",
              "--no-summary",
              "-v",
            },
          },
        }),
      },
    })
  end,
} 