# Neovim Python开发指南

本文档介绍如何使用Neovim进行Python开发，替代PyCharm等IDE的功能。

## 设置环境

1. 确保您已经安装了所有必要的插件和工具：
   ```bash
   # 在终端中运行设置脚本
   ~/.config/nvim/scripts/setup_python_env.sh
   ```

2. 在Neovim中安装插件：
   ```
   :Lazy
   ```

3. 安装Python语言服务器：
   ```
   :MasonInstall pyright ruff-lsp black isort debugpy
   ```

## 主要功能及快捷键

### 代码编辑和导航

| 快捷键 | 功能 |
|--------|------|
| `gd` | 转到定义 |
| `gr` | 查找引用 |
| `gh` | 查看文档 |
| `<leader>rn` | 重命名变量/函数 |
| `<leader>ca` | 显示代码操作 |
| `<leader>o` | 切换代码大纲视图 |
| `<leader>fp` | 打开项目导航 |

### 环境管理

| 快捷键 | 功能 |
|--------|------|
| `<leader>pe` | 选择Python环境 |
| `<leader>pc` | 显示当前Python环境 |

### 代码格式化和修复

| 快捷键 | 功能 |
|--------|------|
| `<leader>pi` | 修复Python导入 |
| `<leader>pd` | 生成Python文档字符串 |

### 调试

| 快捷键 | 功能 |
|--------|------|
| `<leader>db` | 切换断点 |
| `<leader>dc` | 开始/继续调试 |
| `<leader>do` | 单步调试（跳过函数） |
| `<leader>di` | 单步调试（进入函数） |
| `<leader>dr` | 打开调试控制台 |

### 测试

| 快捷键 | 功能 |
|--------|------|
| `<leader>tt` | 运行当前测试 |
| `<leader>tf` | 运行当前文件的所有测试 |
| `<leader>ts` | 打开测试摘要 |

### 代码检查和诊断

| 快捷键 | 功能 |
|--------|------|
| `<leader>xx` | 切换问题列表 |
| `<leader>xw` | 显示工作区诊断 |
| `<leader>xd` | 显示文档诊断 |
| `<leader>cd` | 显示光标位置诊断 |

## 特性对比：Neovim vs PyCharm

| 功能 | Neovim配置 | PyCharm |
|------|------------|---------|
| 代码补全 | ✅ nvim-cmp + pyright | ✅ |
| 类型检查 | ✅ pyright + mypy | ✅ |
| 代码导航 | ✅ nvim-lspconfig + telescope | ✅ |
| 重构工具 | ✅ refactoring.nvim + lspsaga | ✅ |
| 调试支持 | ✅ nvim-dap-python | ✅ |
| 测试支持 | ✅ neotest + pytest | ✅ |
| 环境管理 | ✅ swenv.nvim | ✅ |
| 代码规范检查 | ✅ ruff + nvim-lint | ✅ |
| 代码格式化 | ✅ black + isort + conform.nvim | ✅ |
| 项目结构 | ✅ neo-tree.nvim | ✅ |
| 版本控制 | ✅ gitsigns + fugitive | ✅ |

## 智能编码功能

### 自动补全

- 函数/方法补全
- 导入补全
- 路径补全
- 参数补全
- 类型提示

### 代码片段

使用LuaSnip提供常用Python代码片段：

| 前缀 | 展开为 |
|------|--------|
| `class` | 创建类模板 |
| `def` | 创建函数 |
| `defm` | 创建方法 |
| `prop` | 创建属性 |
| `if` | If语句 |
| `ife` | If-Else语句 |
| `for` | For循环 |
| `try` | Try-Except块 |
| `imp` | Import语句 |
| `fimp` | From-Import语句 |
| `main` | 主函数模板 |
| `doc` | 文档字符串 |

## 常见问题解决

### 环境管理问题

如果项目虚拟环境没有被正确检测：

1. 使用 `<leader>pe` 手动选择虚拟环境
2. 确保项目目录中有标准的 `venv`、`env` 或 `.venv` 目录
3. 检查是否正确安装了 `swenv.nvim` 插件

### LSP服务器问题

如果代码提示或补全不工作：

1. 检查 LSP 服务器状态: `:LspInfo`
2. 尝试重启LSP: `:LspRestart`
3. 确保安装了正确的依赖: `:MasonInstall pyright ruff-lsp`

### 格式化问题

如果代码格式化不工作：

1. 确保安装了 black 和 isort: `pip install black isort`
2. 检查 conform.nvim 配置
3. 尝试手动格式化: `:lua vim.lsp.buf.format()`

## 进阶配置

请参考各插件文档进行更详细的自定义配置：

- [pyright](https://github.com/microsoft/pyright)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- [nvim-dap-python](https://github.com/mfussenegger/nvim-dap-python)
- [neotest](https://github.com/nvim-neotest/neotest)
- [swenv.nvim](https://github.com/ChristianChiarulli/swenv.nvim) 