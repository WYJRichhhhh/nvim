-- 独立仓库开发时使用同级 checkout；其他机器交给 lazy.nvim 从 GitHub 安装。
local sibling = vim.fs.normalize(vim.fn.stdpath("config") .. "/../dev-theme.nvim")
return {
    "WYJRichhhhh/dev-theme.nvim",
    dir = vim.fn.isdirectory(sibling) == 1 and sibling or nil,
    main = "dev_theme",
    lazy = false,
    priority = 1000,
    dependencies = {
        "scottmckendry/cyberdream.nvim",
        { "catppuccin/nvim", name = "catppuccin" },
        "folke/tokyonight.nvim",
        { "rose-pine/neovim", name = "rose-pine" },
        "ellisonleao/gruvbox.nvim",
        "shaunsingh/nord.nvim",
        "Mofiqul/dracula.nvim",
        "neanias/everforest-nvim",
        "ribru17/bamboo.nvim",
        "rebelot/kanagawa.nvim",
    },
    opts = {
        -- 沿用原状态与备份目录，迁移时保留当前主题和透明度。
        state_dir = vim.fs.normalize(vim.fn.stdpath("config") .. "/../dev-theme"),
        theme = "cyberdream-light",
        adapters = {
            nvim = { enabled = true },
            ghostty = { enabled = true },
            tmux = { enabled = true },
        },
        cli = { enabled = true },
    },
    keys = {
        { "<leader>tt", "<cmd>DevTheme<cr>", desc = "预览与同步三端配色" },
    },
}
