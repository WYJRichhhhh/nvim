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
        { "rcarriga/nvim-notify" },
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        
        -- 设置默认的一些行为
        telescope.setup({
            extensions = {
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                    case_mode = "smart_case",
                },
                notify = {
                    -- 为notify扩展添加配置
                    results_title = "通知历史",
                    prompt_title = "搜索通知",
                    entry_maker = function(entry)
                        -- 自定义回调处理函数，用于在选择消息时添加q键关闭功能
                        return {
                            value = entry,
                            display = entry.title .. " " .. entry.message,
                            ordinal = entry.title .. " " .. entry.message,
                            on_select = function(prompt_bufnr)
                                actions.close(prompt_bufnr)
                                -- 显示通知详情
                                local win = require("notify").open(entry)
                                if win then
                                    -- 为详情窗口添加q键映射
                                    local buf = vim.api.nvim_win_get_buf(win)
                                    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
                                end
                            end,
                        }
                    end,
                },
            },
        })
        
        -- 加载扩展
        telescope.load_extension("notify")
    end,
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
        notify = {
            -- 可以添加notify扩展的特定配置
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
