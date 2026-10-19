# Ghostty、tmux 与 Neovim 统一主题

主题选择器已拆分为独立插件 [dev-theme.nvim](https://github.com/WYJRichhhhh/dev-theme.nvim)。本仓库只保留 lazy.nvim 的接入声明，不再维护另一份主题引擎或配色快照。

## 本配置中的操作

按空格 `t t` 或执行 `:DevTheme` 打开实时预览。`j/k`、上下键切换，`gg/G` 跳到首尾，回车应用，Esc 或 `q` 恢复并退出。启用的 Ghostty、tmux 与当前 Neovim 都会真实跟随预览。

提供 26 套预设；喜欢绿色可以先看 Bamboo Multiplex、Everforest Dark Soft / Medium。完整主题列表、安装要求和适用环境见插件的 [中文 README](https://github.com/WYJRichhhhh/dev-theme.nvim/blob/main/README.zh-CN.md)。

本配置显式启用 Neovim、Ghostty、tmux 三个适配器，并保留 `<leader>tt` 快捷键。独立插件默认只管理 Neovim，其他用户不需要采用本仓库的配置。

## 独立仓库与本地开发

本机将两个仓库放在同一级：

```text
~/.config/nvim/             个人编辑器配置
~/.config/dev-theme.nvim/   独立主题插件仓库
~/.config/dev-theme/        本机主题状态、生成配置与备份
```

[lua/plugins/dev-theme.lua](../lua/plugins/dev-theme.lua) 优先加载同级插件 checkout；不存在时使用 GitHub 来源。其他机器通过 lazy.nvim 安装，不需要复制本机路径。

迁移沿用原来的 `~/.config/dev-theme`，主题、不透明度与原配置备份得以保留。状态和备份不在任一 Git 仓库中。

## 常用维护命令

```vim
:DevTheme install
:DevTheme current
:DevTheme apply bamboo-multiplex
:DevTheme opacity 0.88
:DevTheme recover
:DevTheme health
```

`:DevTheme install` 会备份后接入已启用适配器的配置，并安装本配置选择启用的 shell 命令。随后可使用 `dev-theme`、`dev-theme list`、`dev-theme apply everforest-dark-soft`。

移除插件前执行 `:DevTheme uninstall`，还原外部配置，再按提示重载 Ghostty/tmux。状态与备份保留以供检查，插件文档说明如何处理安装后新增的配置改动。

## 已知限制

- macOS 修改 Ghostty 不透明度后，需要完全退出再打开；普通主题色可以热重载。
- tmux 已使用明确的主题 RGB，防止 OSC 10/11 返回旧的客户端颜色。Ghostty 的 `background-opacity-cells` 继续让显式背景保留透明度。
- 已运行的 TUI 可能缓存自己的颜色。例如 Codex 0.163.0 在深浅切换后，需要正常 `/quit`，再用 `codex resume` 选择原对话；插件不会重启正在运行的任务。
- Linux Ghostty 自动重载需要自定义命令或手动操作，Windows 暂不支持。
- 独立版仍是实验版本。反馈、主题适配与通用修复请提交到 [插件 Issues](https://github.com/WYJRichhhhh/dev-theme.nvim/issues)。
