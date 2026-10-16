# init.lua 启动配置详解

这份配置使用 Lua 编写，以 lazy.nvim 管理插件。阅读 `init.lua` 时，需要区分 Lua 语法、Neovim 提供的接口和 lazy.nvim 定义的配置字段。三者写在同一份代码里，但各自负责不同的事情。

本文按仓库中 [init.lua](../init.lua) 的执行顺序，解释变量、table、函数调用、模块加载、运行时路径和插件初始化。适合第一次阅读配置的新用户，也适合一段时间没有使用 Neovim 后重新熟悉它。代码片段省略了部分注释，实际行为以仓库配置为准。

## 启动配置的整体职责

普通启动时，Neovim 从配置目录读取 `init.lua`，依次执行其中的顶层代码。使用 `-u` 等启动参数可以改变这一行为。

本仓库的入口主要完成以下工作：

1. 设置 LSP 日志级别和 leader。
2. 找到 lazy.nvim；尚未安装时，用 Git 下载。
3. 将 lazy.nvim 加入运行时搜索路径。
4. 调用 lazy 的 `setup()`，读取插件声明并组织加载。
5. 加载选项、快捷键和自动命令等核心配置。

```text
启动 Neovim
    ↓
执行 init.lua
    ↓
设置日志和 leader
    ↓
找到或安装 lazy.nvim
    ↓
加入 runtimepath
    ↓
lazy.setup：导入声明、加载启动插件、登记按需加载条件
    ↓
加载 core.options、core.keymaps、core.autocmds
    ↓
后续操作和事件触发功能
```

`init.lua` 中没有切换工作目录的代码。初始目录通常继承自启动进程，后续也可能被会话恢复或用户操作改变。配置目录、插件安装目录和当前工作目录彼此独立。

## Lua 语法和 Neovim 接口的边界

看这一行：

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
```

| 部分 | 来源和作用 |
| --- | --- |
| `local` | Lua 语法，定义局部变量 |
| `..` | Lua 运算符，连接字符串 |
| `vim` | Neovim 创建的全局对象 |
| `vim.fn.stdpath()` | Neovim 提供的函数接口 |
| `"data"` | 传给函数的字符串参数 |

Lua 负责执行程序，Neovim 通过 `vim` 暴露编辑器能力。`vim` 不需要单独安装，也不是普通 Lua 解释器自带的标准库。

在 Neovim 中执行：

```vim
:lua print("你好")
:lua print(vim.fn.getcwd())
```

第一条调用 Lua 的 `print()`，第二条通过 Neovim 接口读取当前工作目录。

### 变量和条件判断

```lua
-- 双横线之后是注释
local name = "manor"
local enabled = true
local missing = nil

if not enabled then
    print("没有启用")
end
```

`local` 变量在所属作用域内可见，配置中优先使用它可以减少全局名字冲突。`nil` 表示没有值，`not` 表示逻辑取反，`end` 结束代码块。

Lua 中只有 `false` 和 `nil` 被当作假。数字 `0` 和空字符串 `""` 都被当作真。

字符串使用 `..` 连接：

```lua
local path = "/somewhere" .. "/lazy"
-- path 的值为 /somewhere/lazy
```

### table 同时表示字典和数组

```lua
local settings = {
    enabled = true,
    title = "插件管理",
}

print(settings.enabled)
print(settings["enabled"])
```

后两行在这里读取同一个字段。`enabled = true` 是 `['enabled'] = true` 的简写。

数组也用 table，连续的数组元素从下标 1 开始：

```lua
local names = { "插件A", "插件B" }
print(names[1]) -- 插件A
```

两种形式可以混合：

```lua
local plugin = {
    "saghen/blink.cmp",
    lazy = false,
}
```

它等价于：

```lua
local plugin = {
    [1] = "saghen/blink.cmp",
    ["lazy"] = false,
}
```

lazy 约定用第 1 项作为插件来源。这个含义来自 lazy，Lua 本身只看到一张 table。

### 函数和回调

```lua
local function hello()
    print("你好")
end

hello()
```

`function` 创建函数，`hello()` 才调用它。函数可以像字符串、table 一样，作为值传递给其他函数：

```lua
vim.keymap.set("n", "<leader>x", function()
    print("按键触发")
end)
```

配置加载时，`vim.keymap.set()` 立即执行，登记映射；匿名函数里的 `print()` 要等按键发生后才执行。这种交给其他组件、以后再调用的函数称为回调函数。

## 常见的 vim 接口

| 接口 | 用途 | 示例 |
| --- | --- | --- |
| `vim.g` | 访问 Vim 全局变量 `g:` | `vim.g.mapleader = " "` |
| `vim.opt` | 访问和修改编辑器选项 | `vim.opt.number = true` |
| `vim.bo` | 访问 buffer 选项 | `vim.bo.filetype` |
| `vim.wo` | 访问窗口选项 | `vim.wo.number` |
| `vim.fn` | 调用 Vimscript 函数 | `vim.fn.stdpath("data")` |
| `vim.api` | 调用 Neovim 核心 API | `vim.api.nvim_get_current_buf()` |
| `vim.keymap` | 设置和删除快捷键 | `vim.keymap.set()` |
| `vim.cmd` | 执行 Ex 命令 | `vim.cmd("pwd")` |
| `vim.uv` | 使用 libuv 的文件系统、定时器等接口 | `vim.uv.fs_stat(path)` |
| `vim.lsp` | 配置和调用内置 LSP 客户端 | `vim.lsp.buf.hover()` |

这些入口按用途划分，不是依次加载的插件。不同选项也有不同作用域，例如全局、窗口或 buffer；使用前可以通过 `:help` 查看具体选项的规则。

## 提前设置日志和 leader

```lua
vim.lsp.log.set_level("warn")
vim.g.mapleader = " "
vim.g.maplocalleader = " "
```

第一行设置 LSP 日志级别，让日常日志主要记录警告和更严重的问题。它本身不启动语言服务器。

`vim.g.mapleader` 对应 Vimscript 中的 `g:mapleader`：

```vim
let g:mapleader = " "
```

设置为空格后，映射中的 `<leader>ef` 就表示依次按空格、`e`、`f`。`<leader>` 在建立映射时展开，所以必须在插件和核心快捷键配置之前设置。

`maplocalleader` 提供另一个前缀，常用于文件类型相关的映射。不过 `<localleader>` 不会自动让映射只在某个 buffer 内生效，仍需使用 `{ buffer = ... }` 等设置限定作用域。

## 确定 lazy 的安装目录

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
```

`stdpath()` 返回 Neovim 约定的标准目录，具体位置可能随系统和环境变量变化。这样配置不必写死某台机器的绝对路径。

| 调用 | 用途 |
| --- | --- |
| `vim.fn.getcwd()` | 当前窗口实际使用的工作目录 |
| `vim.fn.stdpath("config")` | 配置目录，包含 `init.lua` 等 |
| `vim.fn.stdpath("data")` | 数据目录，常用于安装插件和工具 |
| `vim.fn.stdpath("state")` | 日志、历史等状态目录 |
| `vim.fn.stdpath("cache")` | 缓存目录 |

可以在 Neovim 中查看实际结果：

```vim
:pwd
:lua print(vim.fn.stdpath("config"))
:lua print(vim.fn.stdpath("data"))
```

切换项目工作目录不会改变 `stdpath("data")`。lazy 和其他插件继续保存在统一的数据目录下，无需在每个项目重新安装。

## 首次启动时引导安装 lazy

```lua
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
```

`vim.uv.fs_stat()` 查询路径信息。成功时返回文件信息 table，失败时返回 `nil` 和错误信息。放在这个条件中时，只使用第一个返回值。

因此，查不到路径时会调用 `vim.fn.system()`，运行外部 Git 命令。参数列表对应：

```sh
git clone --filter=blob:none --branch=stable \
  https://github.com/folke/lazy.nvim.git 安装目录
```

`--filter=blob:none` 减少初始下载的数据量；`--branch=stable` 选择 stable 分支；最后一项指定目标目录。这里的 `system()` 会等待命令完成，因此后面的模块加载发生在下载命令返回之后。

这是引导安装：先用少量代码准备插件管理器，再让管理器接管其他插件。当前代码没有显式检查 Git 退出状态；首次安装需要可用的 Git 和网络，下载失败可能导致后续 `require("lazy")` 报找不到模块。

## 将 lazy 加入 runtimepath

```lua
vim.opt.rtp:prepend(lazypath)
```

`rtp` 是 `runtimepath` 的缩写。它是一组目录，Neovim 会在其中寻找 Lua 模块、插件脚本、文件类型配置和帮助文件等资源。

常见运行时目录结构：

```text
某个运行时目录/
├── lua/        Lua 模块
├── plugin/     插件启动脚本
├── ftplugin/   文件类型配置
├── syntax/     语法定义
└── doc/        帮助文档
```

下载成功只说明代码存在于磁盘。将 lazy 目录加入运行时路径后，Neovim 的 Lua 模块查找机制才能找到其中的 `lua/lazy/init.lua`。

这里的 `:` 是 Lua 方法调用语法：

```lua
object:method(value)
-- 等价于：
object.method(object, value)
```

冒号会自动把对象作为第一个参数传入。`vim.opt.rtp` 是选项对象，`prepend()` 把路径放到列表前面。

普通选项赋值和列表修改的写法不同：

```lua
vim.opt.number = true
vim.opt.rtp:prepend(lazypath)
```

## require 如何加载模块

```lua
require("lazy").setup({ ... })
```

可以拆成两步：

```lua
local lazy = require("lazy")
lazy.setup({ ... })
```

`require()` 是 Lua 的模块加载函数。它查找模块，执行模块代码，再返回模块导出的值。

例如：

```lua
-- lua/demo.lua
local M = {}

function M.hello()
    print("你好")
end

return M
```

其他文件可以使用：

```lua
local demo = require("demo")
demo.hello()
```

`M` 只是常用的变量名，可以理解为 module；真正决定导出值的是 `return M`。

在 Neovim 的运行时模块查找中，常见对应关系如下：

| 调用 | 常见模块位置 |
| --- | --- |
| `require("demo")` | `lua/demo.lua` 或 `lua/demo/init.lua` |
| `require("core.options")` | `lua/core/options.lua` 或 `lua/core/options/init.lua` |
| `require("lazy")` | lazy 插件中的 `lua/lazy/init.lua` |

### 模块缓存

首次加载的模块结果通常保存在 `package.loaded` 中：

```lua
package.loaded["demo"]
```

后续 `require("demo")` 通常返回缓存，不重新执行模块文件。没有显式返回值、也没有自行设置模块缓存的配置文件，在正常加载后通常以 `true` 标记为已加载。

因此，修改磁盘上的配置文件，不代表当前 Neovim 已经执行新代码。重新执行也不一定清除上次登记的事件、定时器等状态。学习和修改配置时，重启是确认完整初始化结果的直接方法。

### setup 是插件提供的普通函数

`setup` 不是 Lua 关键字，也不是所有模块必须实现的函数。许多 Neovim 插件约定用它接收配置和完成初始化。

例如：

```lua
require("mini.files").setup({})
```

通常负责配置资源面板；实际打开面板仍需要调用 `open()`。初始化和功能调用发生在不同时间。

## lazy 的配置 table

```lua
require("lazy").setup({
    spec = { ... },
    defaults = { ... },
    install = { ... },
    checker = { ... },
})
```

Lua 创建 table，lazy 读取其中的字段。`spec`、`defaults` 等字段的含义由 lazy 定义，并非 Lua 语言规定。

### spec 导入插件声明

```lua
spec = {
    { import = "plugins" },
},
```

本仓库通过它导入 `lua/plugins/` 下的插件声明。例如：

```lua
return {
    "某个作者/某个插件",
    event = "BufReadPre",
    opts = {},
}
```

lazy 读取这张 table，知道插件来源、加载条件和初始化参数。读取声明文件时，里面的顶层 Lua 代码会执行，但 `config = function() ... end` 中的函数体要等插件加载时才执行。

`import` 是 lazy 的导入规则，与手动执行 `require("plugins")` 的含义不同。仓库未导入的目录不会因为名字里有 `plugins` 就自动成为插件声明来源。

### defaults 设置加载和版本选择的默认值

```lua
defaults = {
    lazy = true,
    version = false,
},
```

`lazy = true` 表示默认按需加载。单个插件可以覆盖：

```lua
return {
    "folke/snacks.nvim",
    lazy = false,
}
```

常见触发方式：

| 声明 | 加载时机 |
| --- | --- |
| `lazy = false` | 启动时加载 |
| `event = "BufReadPre"` | 读取文件前 |
| `ft = "python"` | Python 文件类型触发时 |
| `cmd = "Mason"` | 执行相应命令时 |
| `keys = ...` | 第一次执行相应快捷键时 |
| `require("插件模块")` | lazy 可按模块需求触发加载 |

`version = false` 表示默认不按语义版本标签选版，通常跟随所选 Git 分支。它不会禁用 Git，也不会禁用锁文件。插件仍可用 `version`、`branch`、`tag` 或 `commit` 指定自己的版本规则。

例如，仓库中的 blink 使用 `version = "1.*"`，覆盖默认规则，选择 1.x 发布版本。`lazy-lock.json` 记录插件对应的 Git 提交，便于恢复版本。普通重启不会自动升级全部已安装插件。

### install 安装缺失插件

```lua
install = {
    missing = true,
    colorscheme = { "cyberdream" },
},
```

`missing = true` 允许在启动时安装声明中缺失的插件。`colorscheme` 指定启动安装期间尝试使用的主题。日常使用的主题仍由 [主题配置](../lua/plugins/cyberdream.lua) 设置。

### checker 检查更新

```lua
checker = { enabled = true },
```

启用可用更新检查。检查更新和执行更新是两件事；发现新提交不会直接替换当前代码。可以在 `:Lazy` 界面查看和执行更新。

### dev 使用本地开发版本

```lua
dev = {
    path = "~/git",
    fallback = true,
},
```

显式设置 `dev = true` 的插件可使用 `~/git` 下的本地目录，适合修改插件源码。`fallback = true` 表示本地目录不存在时，回退到 Git 来源；后续下载仍需要网络可用。

这个设置不会让所有插件自动使用本地代码。默认情况下，没有启用开发模式的插件仍按普通安装规则处理。

### ui 配置插件管理界面

```lua
ui = {
    title = " lazy.nvim 💤",
    border = "rounded",
    pills = false,
},
```

这些字段控制 `:Lazy` 界面的标题、边框和按钮显示，不控制 Neovim 所有浮窗。输入框、补全菜单等界面由各自插件配置。

### performance 禁用部分内置运行时插件

```lua
performance = {
    rtp = {
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
```

这里禁用的是编辑器自带的部分运行时插件脚本，主要涉及压缩文件、归档浏览、HTML 导出、目录浏览和教程入口。目录浏览已交给 mini.files。

这份列表与 lazy 管理的第三方插件声明不是同一层配置。禁用某个插件入口，也不等于删除它所依赖的所有编辑器基础能力。

### change_detection 检测插件声明变化

```lua
change_detection = {
    enabled = true,
    notify = false,
},
```

lazy 检测插件声明的变化，并重新读取声明；`notify = false` 关闭相应通知。

它不保证已经加载的插件配置、注册过的回调或运行中的 LSP 会话全部重新初始化。修改核心配置或插件初始化代码后，重启能避免旧状态影响观察结果。

## 加载核心选项和行为

```lua
require("core.options")
require("core.keymaps")
require("core.autocmds")
```

这三行直接执行仓库自己的模块：

| 模块 | 主要职责 |
| --- | --- |
| [core.options](../lua/core/options.lua) | 编辑器选项，如分屏方向、缩进、撤销等 |
| [core.keymaps](../lua/core/keymaps.lua) | 全局快捷键和对应的功能入口 |
| [core.autocmds](../lua/core/autocmds.lua) | 监听事件，登记自动行为 |

它们位于 `lazy.setup()` 之后。因此启动插件的初始化可能早于这些核心选项，不能假定所有插件在初始化时都已经看到 `core.options` 的设置。leader 等有明确顺序要求的值才放在入口前面。

以资源面板快捷键为例，加载核心模块时只登记映射；按键之后才执行打开面板的回调，并可能通过 `require("mini.files")` 触发插件加载。

自动命令遵循相同模式：

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
    callback = function()
        print("文件保存了")
    end,
})
```

执行配置时登记监听；保存文件后，Neovim 再调用 `callback`。配置文件的顶层代码执行结束后，登记过的按键和事件仍然有效。

## 从加载到调用的生命周期

| 阶段 | 负责组件 | 发生的事情 |
| --- | --- | --- |
| 安装 | lazy.nvim | 将插件源码放到数据目录 |
| 导入声明 | lazy.nvim | 读取插件配置，建立依赖和触发规则 |
| 加载 | lazy.nvim 和 Neovim 运行时 | 使插件模块可用，执行相关脚本和配置 |
| 初始化 | 插件的 `setup()` 或自定义 `config` | 设置状态、注册事件和其他行为 |
| 调用 | 按键回调、自动命令或其他模块 | 打开面板、请求补全、执行格式化等 |
| 退出 | Neovim、插件及其管理的进程 | 保存需要的状态，结束或清理资源 |

已加载的 Lua 模块通常持续到 Neovim 退出。关闭资源面板只是关闭界面，不会卸载插件。LSP、终端和调试进程各有自己的生命周期，也不会因为重新读取一份 Lua 文件就自动重启。

插件管理器 lazy.nvim 负责插件代码的安装和加载；Mason 负责安装语言服务器、格式化器等外部工具。工具安装完成后，再由 LSP、Conform 或 DAP 等组件调用。

## 在 Neovim 中观察配置

可以依次执行以下命令，把抽象概念对应到当前状态：

```vim
:pwd
:lua print(vim.fn.stdpath("config"))
:lua print(vim.fn.stdpath("data"))
:set runtimepath?
:Lazy
:verbose nmap <Space>ef
:lua print(package.loaded["mini.files"] ~= nil)
```

先查看目录和插件状态，再按 `<leader>ef` 打开资源面板，观察 mini.files 的加载情况。已经加载过时，再次打开不会重新加载整个模块。`:verbose nmap` 可以帮助查看映射内容及来源。

查看全局工作目录和实际生效目录是否不同：

```vim
:pwd
:lua print(vim.fn.getcwd(-1, -1))
```

局部窗口或标签页目录可能让两者不同。当前入口没有统一维护所有插件的项目根；如需理解 buffer、窗口、LSP 与工作目录的关系，可继续阅读 [Vim 和 Neovim 心智模型](vim-mental-model.md)。

## 官方参考

- [Lua 5.1 手册中的 require 和模块缓存](https://www.lua.org/manual/5.1/manual.html#pdf-require)
- [lazy.nvim 插件声明](https://lazy.folke.io/spec)
- [lazy.nvim 按需加载](https://lazy.folke.io/spec/lazy_loading)
- [lazy.nvim 全局配置](https://lazy.folke.io/configuration)

Neovim 内置帮助适合查询本机版本的具体接口：

```vim
:help lua-guide
:help lua-require
:help vim.opt
:help vim.fn
:help vim.uv
:help runtimepath
:help stdpath()
:help current-directory
```
