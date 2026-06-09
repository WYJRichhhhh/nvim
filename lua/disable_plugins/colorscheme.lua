-- 主题 / 配色（按需取消注释你偏好的那段，或换成自己的）
-- Kanagawa 主题（自定义调色板）
return {
    -- https://github.com/rebelot/kanagawa.nvim
    "rebelot/kanagawa.nvim", -- 可替换成你喜欢的配色方案
    lazy = false, -- 希望配色在启动 Neovim 时立即加载
    priority = 1000, -- 比其它非懒加载插件更早加载配色
    opts = {
        -- 替换成你的配色专属设置，或删掉以使用默认值
        -- transparent = true,
        background = {
            -- light = "lotus",
            dark = "wave", -- "wave, dragon"
        },
        colors = {
            palette = {
                -- 背景色
                sumiInk0 = "#161616", -- 已修改
                sumiInk1 = "#181818", -- 已修改
                sumiInk2 = "#1a1a1a", -- 已修改
                sumiInk3 = "#1F1F1F", -- 已修改
                sumiInk4 = "#2A2A2A", -- 已修改
                sumiInk5 = "#363636", -- 已修改
                sumiInk6 = "#545454", -- 已修改

                -- 弹窗与浮动窗口
                waveBlue1 = "#322C47", -- 已修改
                waveBlue2 = "#4c4464", -- 已修改

                -- Diff 与 Git
                winterGreen = "#2B3328",
                winterYellow = "#49443C",
                winterRed = "#43242B",
                winterBlue = "#252535",
                autumnGreen = "#76A56A", -- 已修改
                autumnRed = "#C34043",
                autumnYellow = "#DCA561",

                -- 诊断
                samuraiRed = "#E82424",
                roninYellow = "#FF9E3B",
                waveAqua1 = "#7E9CD8", -- 已修改
                dragonBlue = "#7FB4CA", -- 已修改

                -- 前景色与注释
                oldWhite = "#C8C093",
                fujiWhite = "#F9E7C0", -- 已修改
                fujiGray = "#727169",
                oniViolet = "#BFA3E6", -- 已修改
                oniViolet2 = "#BCACDB", -- 已修改
                crystalBlue = "#8CABFF", -- 已修改
                springViolet1 = "#938AA9",
                springViolet2 = "#9CABCA",
                springBlue = "#7FC4EF", -- 已修改
                waveAqua2 = "#77BBDD", -- 已修改

                springGreen = "#98BB6C",
                boatYellow1 = "#938056",
                boatYellow2 = "#C0A36E",
                carpYellow = "#FFEE99", -- 已修改

                sakuraPink = "#D27E99",
                waveRed = "#E46876",
                peachRed = "#FF5D62",
                surimiOrange = "#FFAA44", -- 已修改
                katanaGray = "#717C7C",
            },
        },
    },
    config = function(_, opts)
        require("kanagawa").setup(opts) -- 可替换成你喜欢的配色方案
        vim.cmd("colorscheme kanagawa") -- 可替换成你喜欢的配色方案

        -- 自定义 diff 颜色
        vim.cmd([[
      autocmd VimEnter * hi DiffAdd guifg=#00FF00 guibg=#005500
      autocmd VimEnter * hi DiffDelete guifg=#FF0000 guibg=#550000
      autocmd VimEnter * hi DiffChange guifg=#CCCCCC guibg=#555555
      autocmd VimEnter * hi DiffText guifg=#00FF00 guibg=#005500
    ]])

        -- 自定义边框颜色
        vim.cmd([[
      autocmd ColorScheme * hi NormalFloat guifg=#F9E7C0 guibg=#1F1F1F
      autocmd ColorScheme * hi FloatBorder guifg=#F9E7C0 guibg=#1F1F1F
    ]])
    end,
}

-- Kanagawa Theme (Original)
-- return {
--   -- https://github.com/rebelot/kanagawa.nvim
--   'rebelot/kanagawa.nvim', -- You can replace this with your favorite colorscheme
--   lazy = false, -- We want the colorscheme to load immediately when starting Neovim
--   priority = 1000, -- Load the colorscheme before other non-lazy-loaded plugins
--   opts = {
--     -- Replace this with your scheme-specific settings or remove to use the defaults
--     -- transparent = true,
--     background = {
--       -- light = "lotus",
--       dark = "wave", -- "wave, dragon"
--     },
--   },
--   config = function(_, opts)
--     require('kanagawa').setup(opts) -- Replace this with your favorite colorscheme
--     vim.cmd("colorscheme kanagawa") -- Replace this with your favorite colorscheme
--   end
-- }

-- Tokyo Night Theme
-- return {
--   -- https://github.com/folke/tokyonight.nvim
--   'folke/tokyonight.nvim', -- You can replace this with your favorite colorscheme
--   lazy = false, -- We want the colorscheme to load immediately when starting Neovim
--   priority = 1000, -- Load the colorscheme before other non-lazy-loaded plugins
--   opts = {
--     -- Replace this with your scheme-specific settings or remove to use the defaults
--     -- transparent = true,
--     style = "night", -- other variations "storm, night, moon, day"
--   },
--   config = function(_, opts)
--     require('tokyonight').setup(opts) -- Replace this with your favorite colorscheme
--     vim.cmd("colorscheme tokyonight") -- Replace this with your favorite colorscheme
--   end
-- }

-- Catppuccin Theme
-- return {
--   -- https://github.com/catppuccin/nvim
--   'catppuccin/nvim',
--   name = "catppuccin", -- name is needed otherwise plugin shows up as "nvim" due to github URI
--   lazy = false, -- We want the colorscheme to load immediately when starting Neovim
--   priority = 1000, -- Load the colorscheme before other non-lazy-loaded plugins
--   opts = {
--   --   -- Replace this with your scheme-specific settings or remove to use the defaults
--     -- transparent = true,
--     flavour = "mocha", -- "latte, frappe, macchiato, mocha"
--   },
--   config = function(_, opts)
--     require('catppuccin').setup(opts) -- Replace this with your favorite colorscheme
--     vim.cmd("colorscheme catppuccin") -- Replace this with your favorite colorscheme
--   end
-- }

-- Sonokai Theme
-- return {
--   -- https://github.com/sainnhe/sonokai
--   'sainnhe/sonokai',
--   lazy = false, -- We want the colorscheme to load immediately when starting Neovim
--   priority = 1000, -- Load the colorscheme before other non-lazy-loaded plugins
--   config = function(_, opts)
--     vim.g.sonokai_style = "default" -- "default, atlantis, andromeda, shusia, maia, espresso"
--     vim.cmd("colorscheme sonokai") -- Replace this with your favorite colorscheme
--   end
-- }

-- One Nord Theme
-- return {
--   -- https://github.com/rmehri01/onenord.nvim
--   'rmehri01/onenord.nvim',
--   lazy = false, -- We want the colorscheme to load immediately when starting Neovim
--   priority = 1000, -- Load the colorscheme before other non-lazy-loaded plugins
--   config = function(_, opts)
--     vim.cmd("colorscheme onenord") -- Replace this with your favorite colorscheme
--   end
-- }
