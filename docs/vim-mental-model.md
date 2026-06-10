# Vim / Neovim 心智模型

这份文档不是命令速查表，而是一套**概念地图**：帮你把零散的 vim 概念归类成体系，记住每一层「为什么存在、负责什么」。具体某个命令怎么用、某个选项有哪些取值，用到时 `:help` 查即可——那是叶子，本文管的是主干。

> 一句话锚点：**一个主角（buffer），七个圈层回答关于它的七个问题，三条哲学贯穿其中。**

## 统领全局的中心：buffer

整个 vim 系统，本质是**围绕 buffer（内存里的文本）展开的同心圆**。

> **buffer 是唯一的主角，其余所有概念都在回答关于 buffer 的某个问题。**

这样下面的分类就不是一堆孤立的盒子，而是从中心向外的圈层——每一圈解决「关于 buffer 的一个问题」。

## 设计目的总表（按「解决什么问题」分类）

| 圈层 | 概念 | 它为 buffer 解决的问题 | 设计目的一句话 |
|---|---|---|---|
| **① 核心对象** | buffer | —— | 把磁盘文件抽象成「内存里可独立操作的文本单元」，编辑与落盘解耦（`:w` 才落盘） |
| **② 怎么看它 / 排布它**（空间） | window / tab | 用哪个取景框看？多个框怎么布局？ | **显示与内容解耦**：一份内容可多窗口看，布局自由组合 |
| **③ 怎么跟它对话**（交互） | 模态 + 编辑语法 + Ex 命令 | 此刻按键什么意思？怎么改一个点？怎么批量改一片？ | **模式复用键盘**；**动宾语法**让少量按键组合出海量操作；**Ex 范围**做非交互批处理 |
| **④ 它是什么货色**（身份） | filetype / buftype / modifiable | 什么语言？真文件还是面板？能不能改？ | **三根正交的标签轴**，决定谁（插件 / LSP / 快捷键）对它生效 |
| **⑤ 编辑器替我记什么**（状态） | register / mark / jumplist / quickfix | 暂存内容放哪？位置怎么标记回跳？一批待办位置怎么管？ | **把「内容」和「位置」做成可复用的记忆**，减少重复定位 |
| **⑥ 谁在背后服务它**（智能） | LSP / Treesitter / diagnostics / completion | 语义从哪来？语法结构从哪来？问题 / 候选怎么呈现？ | **语义（LSP）与语法（Treesitter）两个正交来源**，attach 到 buffer 提供智能 |
| **⑦ 凭什么自动接线**（运行时） | autocmd/事件 · keymap · options 作用域 · runtimepath/目录约定 · lazy 懒加载 | 配置何时、对哪些 buffer、以什么顺序生效？ | **事件驱动 + 目录约定**：在对的时机、对的 buffer 上自动装配 |

## 各圈层展开

### ② 空间：buffer / window / tab —— 内容 / 取景框 / 布局

- **buffer = 内容**：文件读进内存后的文本（连同它的本地选项、undo 历史、标记）。是数据，不一定被显示。`:ls` 能列出一堆屏幕上看不见的 buffer（hidden buffer）。
- **window = 取景框**：一个 window **在任一时刻只对着一个 buffer**；但一个 buffer **可以同时被多个 window 显示**（`:split` 后两窗看同一文件，互不影响滚动）。buffer↔window 是**多对多**，只有「window→当前显示的 buffer」在某一刻是一对一。`Ctrl-w` 系列（`hjkl`/`s`/`v`/`q`）操作的是 window，不是 buffer。
- **tab page = 一套 window 布局**。注意：**vim 的 tab 不是「一个文件一个标签页」**，而是「一组 window 的排布方案」。文件列表那个角色由 **buffer 列表**（`:ls`）扮演。

### ③ 交互：模态 + 编辑语法 + Ex

**模态**是最外层前提——任何操作先问「现在什么模式」：
- **normal**：默认的「家」，是指挥模式而非空闲。用「动词 + 名词」下指令。
- **insert**：唯一真正往里敲字符的模式。反模式是长期赖在 insert 里当记事本用。
- **visual**：先选范围、再施加操作（名词在前、动词在后）。
- **command-line（`:`）**：`:w` `:bnext` 这类 ex 命令。
- 还有 replace、terminal 等。

**编辑语法（交互式、面向单点）**：normal 模式里你在说动宾结构的句子——
- operator（动词）：`d`删 `c`改 `y`复制 `>`缩进 `gu`小写……
- motion（移动/范围）：`w` `}` `G` `f,`……
- text-object（名词）：`iw`词 `i(`括号内 `it`标签内 `ip`段（`i`=inner 内部，`a`=around 含边界）。
- 组合：`动词 + 名词`，如 `diw` `ci(` `yap`。**少量动词 × 少量名词，组合出海量操作**，不靠背快捷键。

**Ex 命令（非交互、面向范围的批处理）** —— 第二根编辑支柱，公式 `:[range][command][flags]`：
- range：`:%`全文、`:1,10`、`:'<,'>`可视选区、`/foo/,/bar/`按模式划界。
- 三个高价值组合：
  - `:%s/old/new/g` —— 全文替换（加 `c` 标志逐个确认）。
  - `:g/pattern/command` —— 对所有匹配行执行命令，如 `:g/TODO/d`、`:g/^$/d`。vim 最强批处理原语。
  - `:%norm! A;` —— 在每行上重放一段 normal 命令，把交互连招一次性施加到一批行。

### ④ 身份：三根正交的属性轴

| 维度 | 选项/概念 | 回答的问题 | 例子 |
|---|---|---|---|
| 是什么内容 | `filetype` | 哪种语言/格式？ | `python` `lua` `markdown` `netrw` |
| 是不是真文件 | `buftype` | 对应磁盘文件，还是面板？ | 空=普通文件；`nofile`/`quickfix`/`terminal`/`help`/`prompt` |
| 能不能改 | `modifiable` / `readonly` | 允许编辑吗？ | 插件面板常 `modifiable=false` |

- `filetype` 是「内容类型」总线：一确定就触发语法高亮、缩进、`ftplugin/` 配置、LSP 是否 attach。「某快捷键/autocmd/插件作用于哪类 buffer」的判据**主要是 filetype**。
- `buftype` 是「功能种类」：打开目录时 vim 用 netrw 接管，展示的是 `buftype=nofile`、`filetype=netrw` 的特殊 buffer，`:w` 对它没意义。telescope/aerial 浮窗、quickfix、`:help`、内置终端都是不同 buftype 的特殊 buffer。
- **「只读/可写」是独立的第三根轴**，跟前两者无关——普通 python 文件也能设成只读。

### ⑤ 状态：编辑器替你记的东西

- **register（寄存器）**：不是单一剪贴板，而是一排带名字的剪贴板。`"ayy`/`"ap` 存取 a 寄存器；`"0` 是最近一次 yank（不被 delete 污染），`"+` 是系统剪贴板，`"_` 是黑洞（删了不污染默认寄存器）。
- **mark（标记）**：`ma` 打书签，`` `a `` 跳回；大写 mark 跨文件。
- **jumplist / changelist**：vim 自动记录「跳转历史」和「修改历史」。`Ctrl-o`/`Ctrl-i` 在跳转史前后走（像浏览器后退/前进），`g;`/`g,` 在修改点间走。
- **quickfix / location list**：跟 jumplist 不同——jumplist 是「我去过哪」，quickfix 是「**一批待处理的位置**」（编译错误、grep 结果、LSP 引用/诊断）。`:copen` 打开，`]q`/`[q` 跳条目。location list 是它的 window-local 版本。

### ⑥ 智能：语义与语法两个正交来源

| 概念 | 心智模型 |
|---|---|
| **LSP** | 独立的语言服务器进程，nvim 作为 client 连上，按 filetype 决定 attach 谁。提供**语义**：跳转/引用/补全/hover/rename/code action |
| **diagnostics** | LSP/linter 报上来的「问题列表」，独立子系统：行内虚拟文本、下划线、符号列、`]d`/`[d` 跳转、可灌进 quickfix |
| **Treesitter** | 把源码解析成**语法树**：更准的高亮、基于语法的 text-object、按结构折叠 |
| **completion** | 候选来源（LSP/缓冲区词/路径/snippet）汇总弹窗 |

关键模型：**LSP 是「语义」来源，Treesitter 是「语法结构」来源，两者正交。** 跳转/诊断怪 → 怀疑 LSP；高亮/折叠/结构 text-object 怪 → 怀疑 Treesitter。

### ⑦ 运行时：配置凭什么自动接线

- **runtimepath & 目录约定**：nvim 在 `runtimepath` 的目录里按固定约定自动加载子目录——`plugin/`（启动时）、`ftplugin/`（对应 filetype 的 buffer 打开时）、`after/`（最后覆盖）。**这就是 `ftplugin/python.lua` 不用手动 require、一打开 python 文件就生效的原因**：`FileType` 事件 + 目录约定在背后接线。
- **options 作用域**：同一选项可能是 global / buffer-local / window-local。`filetype` 是 buffer-local（每个 buffer 各一份），`number` 往往 window-local。理解作用域就懂「为什么这设置只在某些地方生效」。
- **autocmd + 事件**：vim 在特定时机（`BufRead`/`BufEnter`/`FileType`……）触发你注册的回调，是整套配置的「神经系统」。
- **lazy.nvim 懒加载**：插件按触发条件延迟加载——`event`/`ft`/`cmd`/`keys`。心智模型：「在真正需要它的那一刻才 require」，启动才快。

## 最容易混的辨析（记忆防错点）

1. **window vs buffer**：取景框 vs 画面。多对多，但「此刻显示」是一对一。
2. **filetype vs buftype**：「什么内容」vs「是不是真文件」——两根独立的轴。
3. **jumplist vs quickfix**：「我去过哪」（自动回溯，`Ctrl-o`/`Ctrl-i`）vs「一批待处理位置」（`]q`/`[q`）。
4. **LSP vs Treesitter**：语义来源 vs 语法结构来源。出问题时据此定位该怀疑谁。

## 三条贯穿全系统的设计哲学（记目的的总纲）

1. **正交解耦**：内容/显示/身份/智能各管一摊、互不绑死（buffer↔window 多对多、filetype↔modifiable 独立、LSP↔Treesitter 分工）。好处是组合自由、排错时能精确定位是哪一层的问题。
2. **组合优于记忆**：不给几千个专用命令，而给「动词 × 名词 × 次数 × 范围」的语法，以及 `.`/macro/`:g+:norm` 的重复机制。少量正交原语组合出无限操作。
3. **事件驱动的自动装配**：不手动调度，而是声明「在什么时机、对什么 buffer 生效」（autocmd / ftplugin 目录约定 / lazy 懒加载），系统在对的时刻替你接线。

## 重复家族（效率的分水岭，值得刻意练）

- **`.`（dot-repeat）**：把每次编辑设计成可重复的原子操作，操作完立刻 `<Esc>` 封顶，再用 motion 跳到下一处按 `.`。
- **`cgn` + `.`**：`*` 或 `/foo` 设目标 → `cgn` 改下一个匹配 → `<Esc>` → 之后只按 `.` 跳到下一个并重复，`n` 跳过不想改的。比 `:%s` 更可控的批量替换。
- **macro（`q`）**：`qa` 录制 → `q` 停 → `@a` 重放 → `@@` 再来。`.` 重复一个原子操作，macro 重复任意复杂流程。

## 元能力：`:help`

vim 是自文档的：`:help ci(`、`:help :g`、`:help 'buftype'`（选项加引号）、`:help lsp` 都能直达。`Ctrl-]` 跳 tag、`Ctrl-o` 跳回。**这是今后自主深入任何概念的元工具**，比任何第三方教程都权威。

---

至此心智模型闭环。往后不是「还有没有新概念」，而是「把已有圈层里的某个原语练成肌肉记忆」——尤其编辑语法的连招、Ex 的 `:g`/`:norm`、重复家族的 `.`/`cgn`/macro。那是熟练度问题，靠刻意练习，不靠再学新概念。
