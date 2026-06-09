# 项目约定（Neovim 配置）

这是个人 Neovim 配置（lazy.nvim 管理）。改动时遵循以下约定。

## 语言

- 所有代码注释、commit message、文档一律用**中文**。
- 注释要解释「为什么这么做」，而不是复述代码做了什么。沿用现有文件里那种带背景的注释风格（例如 `core/python.lua` 顶部说明为什么不信任 `$VIRTUAL_ENV`）。

## 目录结构

- `init.lua` —— lazy 只 `{ import = "plugins" }`，即**仅加载 `lua/plugins/` 下的插件规格**。
- `lua/plugins/` —— 启用中的插件，一个文件一个（或一组相关）插件。
- `lua/disable_plugins/` —— **禁用插件的唯一机制**：把文件从 `plugins/` 挪到这里即可，lazy 不会扫描此目录。不要用注释整段屏蔽、也不要直接删除——保留在这里方便日后恢复。
- `lua/core/` —— 跨插件共享的纯逻辑模块（无副作用、可被多处 require）。
- `lua/local.lua` —— **机器特定的本地覆盖，已 .gitignore，绝不入库**。见下方「跨机器移植」。
- `ftplugin/` —— 按文件类型的设置；`ftplugin_disable/` 同理是停用的那批。

## 跨机器移植（重要）

这套配置要在多台机器（不同 OS / CPU 架构 / 软件安装路径）上共用，所以**仓库里不能出现任何机器特定的绝对路径**。两条规则：

1. **能自动探测的就自动探测，别写死。**
   - 平台差异用 `jit.os`（`"OSX"`/`"Linux"`/`"Windows"`）和 `jit.arch`（如 `"arm64"`）分支。例：`ftplugin/java.lua` 据此选 jdtls 的 `config_mac_arm`/`config_linux`/…，`core/keymaps.lua` 的 `gx` 据此选 `open`/`xdg-open`/`start`。
   - mason 安装目录统一用 `vim.fn.stdpath("data") .. "/mason"`，不要写 `~/.local/share/nvim/...`。
   - 第三方 jar（jdtls launcher、java-debug、java-test 等）版本号会随升级变化，一律用 `vim.fn.glob(... .. "*.jar")` 匹配，别写死版本号。
   - Python 解释器走 `core.python`（见上节），不写死。

2. **实在无法探测的（如 JDK 安装路径）收敛到 `lua/local.lua`。**
   - 模板是 `lua/local.lua.example`：换新机器时复制为 `lua/local.lua` 再按本机填写。
   - 读取方式是可选的 `pcall(require, "local")`——文件不存在时各处必须优雅退回到自动探测/系统默认，绝不报错。
   - 目前只有 Java 的 JDK 路径属于这一类。**新增「换台机器就得改」的值时，加到 `local.lua`（并同步更新 `.example` 模板），不要散落进各插件配置。**


## Python 环境解析（重要）

「该用哪个 Python 解释器」只有一个事实来源：`lua/core/python.lua`。

- LSP（`nvim-lspconfig.lua` 里的 pyright）和 DAP（`python.lua`）**都必须**调用 `require("core.python")`，绝不各自实现一套解析逻辑——否则会出现「LSP 不报错、一调试就 ModuleNotFoundError」这类解释器不一致的诡异问题。
- 解析策略：从**正在编辑的文件**推断项目根（`M.root`，按 `pyproject.toml` → `uv.lock` → … → `.git` 优先级），再据此找 `.venv`（`M.venv_python`）。**不要**依赖 shell 里 `source` 过的 venv——uv 工作流下 `$VIRTUAL_ENV` 通常是空的。
- 新增任何需要 Python 解释器的功能（linter、test runner 等），同样从这里取，不要新写探测逻辑。

## Python 工具链分工（别重复）

- **pyright** —— 类型检查、跳转/引用、补全、悬停文档。
- **ruff**（mason 装的二进制 `ruff server`，不是已废弃的 `ruff_lsp`）—— 诊断 + lint。未使用导入/变量交给 ruff 报，pyright 关掉以免重复；hover 只让 pyright 出，避免两个来源打架。
- **格式化走 conform**（`ruff_organize_imports` + `ruff_format`，等价 isort+black 但更快）。**不要再引入 black**（已挪到 `disable_plugins/`）。

## 验证

改完配置后，最低限度跑一遍无错启动：

```bash
nvim --headless "+lua print('ok')" +qa 2>&1 | tail -5
```

涉及 Python LSP/DAP 的改动，在一个真实 uv 项目里确认 `pyright` 和 `ruff` 两个 client 都 attach、且解释器解析到项目自己的 `.venv`。临时建的测试工程用完要删掉。
