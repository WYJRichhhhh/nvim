local opt = vim.opt

-- 设置组合键间隔时间
opt.timeoutlen = 300
-- 配置会话保存的内容，包括空白，缓冲区，当前目录，折叠，帮助，标签页，窗口大小，窗口位置，终端，本地选项
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- 行号设置
opt.relativenumber = true
opt.number = true

-- Tab和缩进设置
opt.tabstop = 2 -- tab键的宽度
opt.shiftwidth = 2 -- 每次缩进的宽度
opt.expandtab = true -- 使用空格代替tab
opt.autoindent = true -- 自动缩进
vim.bo.softtabstop = 2 -- 回退缩进的宽度

-- 自动换行
opt.wrap = true

-- 搜索设置
opt.ignorecase = true
opt.smartcase = true

-- 光标所在行高亮
opt.cursorline = true

-- 外观设置
opt.termguicolors = true -- 启用24位色
opt.background = "dark" -- 使用深色主题
opt.signcolumn = "yes" -- 总是显示signcolumn,避免代码抖动

-- 设置退格键可以删除缩进 行尾 行首
opt.backspace = "indent,eol,start"

-- 允许与系统剪切板共享粘贴板内容
opt.clipboard:append("unnamedplus")

-- 分屏方向为水平向右，垂直向下
opt.splitright = true
opt.splitbelow = true

-- a-b 也被视为单词
opt.iskeyword:append("-")

-- 禁用鼠标
opt.mouse = ""

-- 折叠设置
opt.foldlevel = 20 -- 默认展开20
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()" -- 更智能的语法折叠

-- 未保存文件提示
opt.confirm = true

-- 设置默认的shell为zsh
opt.shell = "zsh"

-- 允许夸会话撤销 禁用交换文件
opt.undofile = true
opt.swapfile = false

-- 滚动时光标位置
opt.scrolloff = 12

-- 光标的样式
opt.guicursor = {
    "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50",
    "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
    "sm:block-blinkwait175-blinkoff150-blinkon175",
}

require("telescope").load_extension("ui-select")
