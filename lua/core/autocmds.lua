local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local utils = require("core.utils")

-- 通用设置
local general = augroup("General Settings", { clear = true })

-- 启动时把 cwd 钉到「项目根」,让 telescope 的 find_files/live_grep 始终按整个项目搜。
--
-- 为什么只在第一个 buffer 钉一次(cwd_set):cwd 频繁变化会让 telescope 搜索范围
-- 飘忽不定,故锁死一次后不再更新。
--
-- 为什么是「项目根」而不是「文件所在目录」(旧实现的坑):旧版直接 chdir 到
-- fnamemodify(bufname, ":p:h"),即第一个 buffer 所在的那一级目录。一旦不是用
-- `nvim .` 而是直接打开深层文件(如 manor-server/data/signal_models/xxx.json,
-- 或被 resession 还原上次的深层文件),cwd 就被钉死在那个子目录,导致 find_files
-- 搜不到另一条子树下的文件。改为从该文件向上找 .git 等标记定位真正的项目根。
local cwd_set = false
-- 通用项目根标记(与 python.lua 的 Python 专用 root_markers 刻意分开:那套只服务
-- LSP/DAP 的解释器解析,这里要的是「整个仓库」级别的根,.git 最可靠)。
local root_markers = { ".git", ".hg", ".svn", "package.json", "Makefile", "pyproject.toml" }
autocmd("BufEnter", {
    callback = function()
        if not cwd_set then
            local bufname = vim.api.nvim_buf_get_name(0)
            if bufname ~= "" then
                -- 找不到标记(如散落的单文件)时退回文件所在目录,行为不比旧版差。
                local root = vim.fs.root(bufname, root_markers) or vim.fn.fnamemodify(bufname, ":p:h")
                vim.fn.chdir(root)
                cwd_set = true
            end
        end
    end,
})
-- 这个配置会将cwd设置为当前buffer中打开的文件所在目录，会影响telescope的搜索范围
-- autocmd("BufEnter", {
--     callback = function()
--         if vim.bo.buftype ~= "terminal" then
--             local file_dir = vim.fn.expand("%:p:h")
--             if file_dir ~= vim.fn.getcwd() then
--                 vim.cmd("cd " .. file_dir)
--             end
--         end
--     end,
--     group = general,
--     desc = "Set CWD to file directory",
-- })
-- 禁用新行自动注释功能
autocmd("BufEnter", {
    callback = function()
        vim.opt.formatoptions:remove({ "c", "r", "o" })
    end,
    group = general,
    desc = "Disable New Line Comment",
})

-- 设置Bicep文件的注释字符串,其余filetype可以自行拓展
autocmd("BufEnter", {
    callback = function(opts)
        if vim.bo[opts.buf].filetype == "bicep" then
            vim.bo.commentstring = "// %s"
        end
    end,
    group = general,
    desc = "Set Bicep Comment String",
})

-- 在md和txt文件中启用拼写检查 对中文不友好
-- autocmd("BufEnter", {
--     pattern = { "*.txt" },
--     callback = function()
--         vim.opt_local.spell = true
--     end,
--     group = general,
--     desc = "Enable spell checking on specific filetypes",
-- })

-- 将帮助窗口重定向到浮动窗口
autocmd("BufWinEnter", {
    callback = function(data)
        utils.open_help(data.buf)
    end,
    group = general,
    desc = "Redirect help to floating window",
})

-- 外部改动自动重载 ----------------------------------------------------
-- Neovim 没有内建文件系统监听，autoread（见 options.lua）只授权重载、不主动检测。
-- 所以在几个"用户自然会回到/停在 buffer"的时机主动跑 :checktime 去对比磁盘时间戳，
-- 体感上就接近 IDE 切分支后自动刷新。只对真实文件 buffer 生效，跳过终端等特殊 buftype。
local autoread = augroup("Auto Reload Changed Files", { clear = true })
autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = autoread,
    callback = function()
        -- 命令行窗口（q:）和非普通 buffer 跑 checktime 会报错或无意义，先挡掉
        if vim.fn.getcmdwintype() ~= "" or vim.bo.buftype ~= "" then
            return
        end
        vim.cmd("checktime")
    end,
    desc = "外部改动时自动重载 buffer",
})

-- 重载发生后给一条提示，避免内容"无声无息"变了让人疑惑
autocmd("FileChangedShellPost", {
    group = autoread,
    callback = function()
        vim.notify("文件已被外部修改，buffer 已重载", vim.log.levels.WARN)
    end,
    desc = "外部重载后提示",
})

-- 特定文件类型不进缓冲区 ，并设置快捷键q为关闭缓冲区
autocmd("FileType", {
    group = general,
    pattern = {
        "grug-far",
        "help",
        "checkhealth",
        "copilot-chat",
        "dap-float",
        "qf",
        "diff",
        "notify",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", {
            buffer = event.buf,
            silent = true,
            desc = "Quit buffer",
        })
    end,
})
