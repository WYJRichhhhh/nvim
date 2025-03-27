local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local utils = require("core.utils")

-- General Settings
local general = augroup("General Settings", { clear = true })

-- 自动设置 cwd 为打开文件或目录的路径,解决使用 telescope时 搜索路径不断变化导致项目级别搜索困难的问题
local cwd_set = false
autocmd("BufEnter", {
    callback = function()
        if not cwd_set then
            local bufname = vim.api.nvim_buf_get_name(0)
            if bufname ~= "" then
                local path = vim.fn.fnamemodify(bufname, ":p:h")
                vim.fn.chdir(path)
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
