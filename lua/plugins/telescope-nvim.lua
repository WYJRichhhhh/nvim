-- Fuzzy finder
return {
    -- https://github.com/nvim-telescope/telescope.nvim
    "nvim-telescope/telescope.nvim",
    lazy = true,
    dependencies = {
        -- https://github.com/nvim-lua/plenary.nvim
        { "nvim-lua/plenary.nvim" },
        {
            -- https://github.com/nvim-telescope/telescope-fzf-native.nvim
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function()
                return vim.fn.executable("make") == 1
            end,
        },
    },
    extensions = {
        --["ui-select"] = {
            --require("telescope.themes").get_dropdown({}),
        --},
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
        },
    },
    opts = {
        defaults = {
            cwd = vim.fn.expand("%:p:h"),
            layout_config = {
                vertical = {
                    width = 0.75,
                },
            },
            path_display = {
                shorten = 3,
                truncate = 3,
                -- filename_first = {
                --     reverse_directories = true,
                -- },
            },
        },
    },
}
