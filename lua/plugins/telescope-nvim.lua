-- 模糊查找器
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
            defaults = {
                -- 不设 cwd：让 live_grep/find_files 默认按 getcwd()（即 `nvim .` 的项目根）搜，
                -- 这正是我们要的「搜整个项目」。早先这里设过 cwd=当前文件目录，既不符本意、
                -- 又因写在没生效的顶层 opts 里而从未起作用，故彻底去掉。
                layout_config = {
                    vertical = {
                        width = 0.75,
                    },
                },
                -- 左侧截断:路径原样显示,窗口放不下时只从左边用 … 省略,
                -- 文件名和最近几级目录始终可见——方便区分同名文件(如多个 bootstrap.py)
                -- 到底在哪级目录。不用 shorten:它会把每级目录砍成头几个字母
                -- (management→man、source→src),反而看不出真实路径。
                path_display = {
                    truncate = 3,
                },
            },
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
        -- fzf-native 是 C 扩展，靠 `make` 编译（见 dependencies 里的 cond）。
        -- 没装 make 的机器上它不会编译，load 会失败——用 pcall 兜底优雅退回到
        -- 纯 Lua 的 generic sorter，不让整个 telescope 配置因此报错。
        pcall(telescope.load_extension, "fzf")
    end,
}
