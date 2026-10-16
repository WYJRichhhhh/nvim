# 用 Neovim 和 AI Agent 开发

一套以键盘操作为核心的个人 Neovim 配置，使用 Lua 和 lazy.nvim 管理插件。当前以 **tmux + Neovim** 组织开发环境：在 Neovim 中阅读、编辑和审查代码，在终端中运行服务与 AI Agent。

核心愿景是用键盘完成日常开发，让 AI Agent 承担测试执行、失败排查与回归验证，逐步形成 **AI + Neovim** 的开发工作流。

## 愿景与分工

开发者负责理解需求、做技术判断、修改和审查代码；AI Agent 负责按任务补充测试、执行验证、分析失败并反馈结果。开发者根据代码差异和测试结果决定是否接受改动。

理想中的工作流程是：

```text
理解需求与阅读代码
    ↓
开发者与 AI Agent 协作实现
    ↓
AI Agent 执行测试、分析失败并验证修复
    ↓
开发者在 Neovim 中审查代码与结果
    ↓
通过 Git 提交
```

希望将文件导航、搜索、窗口切换、代码编辑、终端和 Git 操作都收敛到键盘上，减少开发过程对鼠标的依赖。仓库当前已关闭 Neovim 鼠标操作。

## 当前实现与后续方向

| 方向 | 当前状态 |
| --- | --- |
| 键盘开发 | 已配置文件浏览、搜索、跳转、代码大纲、分屏和 Git 操作 |
| 编辑器语言能力 | 已接入 LSP、补全、语法高亮和格式化，Python 共用项目解释器解析 |
| 终端与调试 | 已接入 Snacks 终端、Python DAP 和调试界面 |
| tmux 协作 | 使用 tmux 组织终端与编辑器，配置了 vim-tmux-navigator；跨窗格导航需配合 tmux 端设置 |
| AI 辅助 | 已有基于本机 Claude CLI 的文件问答与选区翻译入口 |
| Agent 测试流程 | 作为目标工作方式，由终端中的 Agent 执行；仓库尚未实现统一的测试委派与结果回传机制 |
| Codex 集成 | 计划在 Neovim 中提供调用入口，具体插件形态和交互方式尚未确定 |
| 减少 tmux 依赖 | 长期希望由 Neovim 承载所需的终端与 Agent 交互，目前继续保留 tmux |

Codex 集成希望连接“编辑上下文、Agent 任务、代码改动、测试结果和审查”。如何传递上下文、展示任务进度、处理会话以及呈现结果，仍需要结合实际使用确定。

现阶段先把已有编辑和终端流程用顺，再决定插件边界。最终是否完全移除 tmux，也取决于 Neovim 内的终端和 Agent 交互能否覆盖日常需要。

## 已有能力

| 功能 | 主要组件 |
| --- | --- |
| 插件管理 | lazy.nvim |
| 文件浏览与工作目录切换 | mini.files，面板内使用 `g=` |
| 文件、文本与符号搜索 | Telescope、Aerial，以及自定义结构搜索 |
| 代码补全与片段 | blink.cmp、Neovim 内置片段能力、friendly-snippets |
| 语言服务与工具安装 | Neovim 内置 LSP、nvim-lspconfig、Mason |
| 语法高亮与折叠 | Treesitter |
| 格式化 | Conform；Python 使用 Ruff |
| Python 调试 | nvim-dap、nvim-dap-python、nvim-dap-ui |
| 终端 | Snacks.terminal |
| Git 审查与提交 | Gitsigns、Diffview、Neogit、Flog、Fugitive |
| 会话恢复 | resession.nvim |

配置会持续调整。插件是否启用，以 [lua/plugins](lua/plugins) 中的声明为准。

## 开始使用

当前配置使用 Neovim 0.12 系列接口及 nvim-treesitter 的 `main` 分支。首次启动会下载插件，并可能安装语言工具和语法解析器。

准备以下基础工具：

- Neovim 0.12 或更新版本。
- Git、curl，以及首次安装时可用的网络。
- Treesitter 解析器安装需要的 C 编译器和 tree-sitter CLI；版本要求见所锁定 nvim-treesitter 的说明。
- `ripgrep`，供项目文本搜索使用。
- `make`，用于构建可选的 Telescope 原生模糊匹配扩展。
- 支持 Nerd Font 图标的终端字体。
- 对应语言工具需要的运行时，例如部分 Mason 工具依赖 Node.js。

从本地配置目录部署。下面的命令适用于尚未放置其他配置的默认目录；已有配置时应先自行备份或使用独立配置目录。

```sh
git clone https://github.com/WYJRichhhhh/nvim.git ~/.config/nvim
nvim
```

首次安装后可以查看：

```vim
:Lazy
:Mason
:checkhealth
```

Python 项目优先使用项目内的 `.venv`。LSP 和调试共用 [core.python](lua/core/python.lua) 的解释器解析，格式化由 Ruff 提供。Claude 问答功能需要本机已有可用的 `claude` CLI；Codex 集成属于后续计划。

这是一套个人工作流配置，语言工具和外部命令仍需根据自己的开发环境准备。

## 日常操作入口

`<leader>` 为空格。下表列出少量常用入口，便于从实际操作开始熟悉配置。

| 按键 | 操作 |
| --- | --- |
| `<leader>ef` | 在 mini.files 中定位当前文件；无实际文件时打开工作目录 |
| mini.files 内的 `l` / `h` | 进入子目录 / 返回父目录 |
| mini.files 内的 `g=` | 将聚焦面板目录设为全局工作目录，并以它为根重新打开面板 |
| mini.files 内的 `=` | 同步面板中的文件操作 |
| `<leader>ff` / `<leader>fg` | 查找文件 / 搜索项目文本 |
| `<leader>fb` | 查找和切换 buffer |
| `<leader>fs` / `<leader>fS` | 结构搜索 / 代码大纲 |
| `gd` / `gr` / `rn` | 跳转定义 / 查找引用 / 重命名 |
| `gf` | 格式化 |
| `Ctrl-j` / `Ctrl-k` | 补全候选向下 / 向上选择 |
| `Alt-i` / `Alt-h` / `Alt-v` | 切换浮动 / 水平 / 垂直终端 |
| `<leader>rp` | 使用项目解释器运行当前 Python 文件 |
| `<leader>db` / `<leader>dc` | 切换断点 / 启动或继续调试 |
| `<leader>gg` / `<leader>gv` | 打开 Neogit / 切换差异查看器 |
| `<leader>aa` | 基于当前文件向 Claude 提问 |
| 可视模式下 `<leader>at` | 将选区交给 Claude 进行翻译讲解 |

工作目录、资源面板目录和 LSP 项目根分别维护。在面板里浏览不会自动切换工作目录；按 `g=` 才会执行切换。已启动的 shell 和 LSP 会话也有各自的目录状态。

使用 `:pwd` 查看当前窗口实际使用的工作目录，查看全局目录可执行：

```vim
:lua print(vim.fn.getcwd(-1, -1))
```

## 学习文档

建议先理解编辑器对象，再阅读启动配置，最后按开发任务查阅指南。

| 文档 | 内容 |
| --- | --- |
| [Vim 和 Neovim 心智模型](docs/vim-mental-model.md) | buffer、窗口、编辑语法、状态、LSP 与运行时机制 |
| [init.lua 启动配置详解](docs/init-lua-guide.md) | Lua 基础、Neovim 接口、require、lazy 配置和插件生命周期 |
| [Python 开发指南](docs/python_development.md) | 早期 Python 工作流记录；部分工具、测试集成和快捷键待同步，以当前配置为准 |
| [Git 工具使用指南](docs/git_tools.md) | Git 变更、差异和历史浏览的操作参考，具体键位以当前插件配置为准 |

## 配置结构

```text
init.lua                 启动入口与 lazy 全局配置
lazy-lock.json           插件版本锁文件
lua/plugins/             启用的插件声明和初始化配置
lua/core/                编辑器设置、快捷键、事件及共享逻辑
ftplugin/                文件类型专用配置
snippets/                自定义代码片段
docs/                    学习与使用文档
```

编辑器选项集中在 [core.options](lua/core/options.lua)，全局快捷键集中在 [core.keymaps](lua/core/keymaps.lua)，自动行为集中在 [core.autocmds](lua/core/autocmds.lua)。只服务某个插件的配置与快捷键，优先放在对应插件文件中。

希望这份仓库既能记录自己的工作流，也能帮助新用户理解每项配置为何存在、由谁加载、何时执行，再逐步形成适合自己的键盘开发环境。
