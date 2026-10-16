-- 日常只记录警告，避免调试日志持续增长。
vim.lsp.log.set_level("warn")
-- leader 在创建快捷键时展开，所以必须先于插件和核心快捷键配置。
vim.g.mapleader = " "

vim.g.maplocalleader = " "
-- 插件管理器需要先自行安装，之后才能接管其余插件的安装与加载。
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- 使用 stable 分支引导安装
        lazypath,
    })
end
-- 下载到磁盘不等于模块可加载；先把 lazy 加入运行时搜索路径。
vim.opt.rtp:prepend(lazypath)

-- 读取插件声明，加载启动插件，并为按需加载的插件登记触发条件。
require("lazy").setup({
    -- 从 lua/plugins/ 导入插件声明；读取声明不等于立即加载全部插件。
    spec = {
        { import = "plugins" },
    },
    -- 设置默认行为
    defaults = {
        lazy = true,
        -- 默认不按语义版本标签选版；单个插件可覆盖，锁文件仍记录 Git 提交。
        version = false,
    },
    -- 自动安装缺失插件；安装期间尝试使用此主题，日常主题由主题插件配置。
    install = {
        missing = true,
        colorscheme = { "cyberdream" },
    },
    -- 检查可用更新，不自动升级已安装插件。
    checker = { enabled = true },
    -- 设置开发插件的路径和策略
    -- path 用家目录相对的 ~/git（任何用户都成立，非机器特定的绝对路径）；
    -- 显式 dev=true 的插件使用本地目录；不存在时回退到 Git 来源。
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
            -- 禁用当前配置未使用的内置运行时插件，目录浏览由 mini.files 接管。
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
        enabled = true, -- 检测并重新读取插件声明，不保证已加载插件的配置完整热重载
        notify = false, -- 检测到声明变化时不弹出通知
    },
})
-- 直接执行核心配置；其中登记的回调在之后的按键或事件发生时执行。
require("core.options")
require("core.keymaps")
require("core.autocmds")
