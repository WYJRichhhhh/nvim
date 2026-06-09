-- 设置lsp的日志级别
-- vim.lsp.set_log_level("debug")
vim.lsp.log_level = "debug"
-- 设置全局leader key
vim.g.mapleader = " "

vim.g.maplocalleader = " "
-- 查找lazy,不存在则clone，将其添加到rtp中
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- 使用最新的稳定版
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- 调用lazy的setup函数,开始加载插件
require("lazy").setup({
    -- 指定插件规范，表示从plguins目录中加载插件
    spec = {
        { import = "plugins" },
    },
    -- 设置默认行为
    defaults = {
        lazy = true,
        -- 禁用版本控制，使用最新的版本
        version = false,
    },
    -- 缺失自动安装插件
    install = {
        missing = true,
        colorscheme = { "cyberdream" },
    },
    -- 启用插件更新检查器
    checker = { enabled = true },
    -- 设置开发插件的路径和策略
    -- path 用家目录相对的 ~/git（任何用户都成立，非机器特定的绝对路径）；
    -- fallback = true 兜底：本地没有对应目录时自动回退到从 git 拉取，不会报错。
    dev = {
        path = "~/git",
        fallback = true,
    },
    -- 设置Lazy可视化界面的ui
    ui = {
        title = " lazy.nvim 💤",
        border = "rounded",
        -- 禁用胶囊式按钮
        pills = false,
    },
    -- 性能优化参数
    performance = {
        rtp = {
            -- 禁用不必要的插件
            disabled_plugins = {
                "gzip",
                "tarPlugin",
                "tohtml",
                "zipPlugin",
                "netrwPlugin",
                "tutor",
            },
        },
    },
    change_detection = {
        enabled = true, -- 自动检测配置文件变更并重新加载界面
        notify = false, -- 插件变更时不弹出通知
    },
})
-- 以下模块不经 lazy 加载，直接 require
require("core.options")
require("core.keymaps")
require("core.autocmds")
