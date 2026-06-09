-- Indentation guides
return {
  -- https://github.com/lukas-reineke/indent-blankline.nvim
  "lukas-reineke/indent-blankline.nvim",
  event = 'VeryLazy',
  main = "ibl",
  opts = {
    enabled = true,
    indent = {
      char = '|',
    },
    -- dashboard 开屏页靠前导空格把 ASCII art 居中，会被误判成缩进，
    -- 在这些特殊 buffer 里关掉缩进参考线，避免出现一片竖线
    exclude = {
      filetypes = {
        "dashboard",
        "help",
        "lazy",
        "mason",
        "NvimTree",
        "neo-tree",
        "Trouble",
        "alpha",
        "lspinfo",
        "TelescopePrompt",
        "TelescopeResults",
      },
      buftypes = { "terminal", "nofile", "prompt" },
    },
  },
}
