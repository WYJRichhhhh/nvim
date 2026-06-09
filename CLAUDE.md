# 项目约定（Neovim 配置）

这是个人 Neovim 配置（lazy.nvim 管理）。改动时遵循以下约定。

## 语言

- 所有代码注释、commit message、文档一律用**中文**。
- 与我对话的所有回复、以及思考过程（thinking）也一律用**中文**。
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

> 这条规则有自动兜底：`.claude/hooks/check_hardcoded_paths.py` 会在每次写 `.lua`
> 后扫描新内容，命中 `/Users/`、`/opt/homebrew`、`~/.local/share/nvim` 等写死路径
> 就回灌中文整改建议。注释行、`local.lua`、`*.example` 模板自动放行。它只是网兜，
> 别依赖它替你思考——下笔时就该用 `stdpath()` / `jit.os` / `vim.env`。


## Python 环境解析（重要）

「该用哪个 Python 解释器」只有一个事实来源：`lua/core/python.lua`。

- LSP（`nvim-lspconfig.lua` 里的 pyright）和 DAP（`python.lua`）**都必须**调用 `require("core.python")`，绝不各自实现一套解析逻辑——否则会出现「LSP 不报错、一调试就 ModuleNotFoundError」这类解释器不一致的诡异问题。
- 解析策略：从**正在编辑的文件**推断项目根（`M.root`，按 `pyproject.toml` → `uv.lock` → … → `.git` 优先级），再据此找 `.venv`（`M.venv_python`）。**不要**依赖 shell 里 `source` 过的 venv——uv 工作流下 `$VIRTUAL_ENV` 通常是空的。
- 新增任何需要 Python 解释器的功能（linter、test runner 等），同样从这里取，不要新写探测逻辑。

## Python 工具链分工（别重复）

- **pyright** —— 类型检查、跳转/引用、补全、悬停文档。
- **ruff**（mason 装的二进制 `ruff server`，不是已废弃的 `ruff_lsp`）—— 诊断 + lint。未使用导入/变量交给 ruff 报，pyright 关掉以免重复；hover 只让 pyright 出，避免两个来源打架。
- **格式化走 conform**（`ruff_organize_imports` + `ruff_format`，等价 isort+black 但更快）。**不要再引入 black**（已挪到 `disable_plugins/`）。

## 代码质量与格式（虽是配置项目，仍按工程标准要求）

这虽然是 nvim 配置，但仍按正经工程标准对待。核心一句话：**同一件事只在一个地方配，配置要聚合、可检索、前后一致。**

- **不重复配置。** 一个设置只写一次。同一份信息（路径、解释器、版本探测逻辑等）只能有一个事实来源——已有的几个来源：Python 解释器走 `core/python.lua`、机器特定值走 `local.lua`、平台分支统一用 `jit.os`/`jit.arch`。需要复用就 require / 抽函数，绝不复制粘贴第二份。新增跨文件共享的纯逻辑放进 `lua/core/`。
- **不前后不一致。** 同类配置用同一套写法、同一种命名风格、同一种习惯（如键位描述 `desc`、option 设置方式）。改了一处对应约定，要同步检查同类的其它处，别留下新旧两种写法并存。
- **配置要聚合，别散落。** 一个插件 / 一项功能的配置集中在它自己的文件里（`lua/plugins/` 一文件一插件、`ftplugin/` 按文件类型）。不要把同一功能的设置拆散塞进好几个不相干的文件，导致「这功能到底在哪配的」要全局搜半天。
- **能聚合表达就别堆散值。** 同一组相关的设置（一批 option、一批 keymap、一组 autocmd）用表 / 循环 / 辅助函数聚合表达，而不是平铺一长串重复的 `vim.keymap.set(...)` / `vim.opt.xxx = ...`。让结构本身说明「这些是一类」。
- **用分割线分区，方便检索。** 一个文件里有多个模块 / 功能分块时，块与块之间加分割线注释，沿用现有风格（见 `nvim-lspconfig.lua` 里 `-- Python ----...`）：

  ```lua
  -- 诊断显示 ------------------------------------------------------------
  ...
  -- 补全 ----------------------------------------------------------------
  ...
  ```

  分割线后写明这块是干嘛的，让人扫一眼就能跳到目标区域。

## 验证

改完配置后，最低限度跑一遍无错启动：

```bash
nvim --headless "+lua print('ok')" +qa 2>&1 | tail -5
```

涉及 Python LSP/DAP 的改动，在一个真实 uv 项目里确认 `pyright` 和 `ruff` 两个 client 都 attach、且解释器解析到项目自己的 `.venv`。临时建的测试工程用完要删掉。
