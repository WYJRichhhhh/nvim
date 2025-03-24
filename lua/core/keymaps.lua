-- Set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap

-- General keymaps
-- map gh ^
keymap.set({ "n", "v" }, "gh", "^", { desc = "行首" })
keymap.set({ "n", "v" }, "gl", "$", { desc = "行尾" })
keymap.set({ "i" }, "jk", "<ESC>", { desc = "ESC" }) -- exit insert mode with jk
keymap.set({ "v" }, "q", "<ESC>", { desc = "ESC" }) -- exit insert mode with jk
keymap.set("i", "<C-b>", "<ESC>^i", { desc = "行首" }) -- go to  beginning
keymap.set("i", "<C-e>", "<End>", { desc = "行尾" }) -- go to end
keymap.set("i", "<C-h>", "<Left>", { desc = "光标左移" }) -- move left
keymap.set("i", "<C-l>", "<Right>", { desc = "光标右移" }) -- move right
keymap.set("i", "<C-j>", "<Down>", { desc = "光标下移" }) -- move down
keymap.set("i", "<C-k>", "<Up>", { desc = "贯标上移" }) -- move up
keymap.set("n", "<leader>wq", ":wq<CR>", { desc = "保存并退出" }) -- save and quit
keymap.set("n", "<leader>wa", ":wa<CR>", { desc = "保存全部" }) -- save all
keymap.set("n", "<leader>qq", ":q!<CR>", { desc = "退出不保存" }) -- quit without saving
keymap.set("n", "<leader>ww", ":w<CR>", { desc = "保存当前buffer" }) -- save
keymap.set("n", "gx", ":!open <c-r><c-a><CR>", { desc = "打开贯标所在的url" }) -- open URL under cursor
keymap.set("n", "q", "<cmd> noh <CR>", { desc = "清除高亮" }) -- clear highlights
keymap.set("n", "<leader>\\w", "<cmd>set wrap!<CR>", { desc = "清除自动换行" }) -- clear highlights
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "垂直分割窗口" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "水平分割窗口" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "分割窗口等宽" }) -- make split windows equal width
keymap.set("n", "<leader>sx", ":close<CR>", { desc = "关闭窗口" }) -- close split window
keymap.set("n", "<M-Up>", ":resize +5<cr>", { desc = "增加窗口高度" }) -- 增加窗口高度
keymap.set("n", "<M-Down>", ":resize -5<cr>", { desc = "减少窗口高度" }) -- 减少窗口高度
keymap.set("n", "<M-Left>", ":vertical resize -5<cr>", { desc = "减少窗口宽度" }) -- 减少窗口宽度
keymap.set("n", "<M-Right>", ":vertical resize +5<cr>", { desc = "增加窗口宽度" }) -- 增加窗口宽度
keymap.set("n", "<C-h>", "<C-w>h", { desc = "光标移动到左侧窗口" }) -- 向左移动
keymap.set("n", "<C-j>", "<C-w>j", { desc = "光标移动到下侧窗口" }) -- 向下移动
keymap.set("n", "<C-k>", "<C-w>k", { desc = "光标移动到上侧窗口" }) -- 向上移动
keymap.set("n", "<C-l>", "<C-w>l", { desc = "光标移动到右侧窗口" }) -- 向右移动

-- Diff keymaps
keymap.set("n", "<leader>cc", ":diffput<CR>", { desc = "unuse" }) -- put diff from current to other during diff
keymap.set("n", "<leader>cj", ":diffget 1<CR>", { desc = "unuse" }) -- get diff from left (local) during merge
keymap.set("n", "<leader>ck", ":diffget 3<CR>", { desc = "unuse" }) -- get diff from right (remote) during merge
keymap.set("n", "<leader>cn", "]c", { desc = "unuse" }) -- next diff hunk
keymap.set("n", "<leader>cp", "[c", { desc = "unuse" }) -- previous diff hunk

-- Vim-maximizer
keymap.set("n", "<leader>sm", ":MaximizerToggle<CR>", { desc = "toggle最大化当前窗口" }) -- toggle maximize tab

-- -- Nvim-tree 插件已禁用 替换为minifile
-- keymap.set("n", "<leader><leader>", ":NvimTreeToggle<CR>") -- toggle file explorer
-- keymap.set("n", "<leader>er", ":NvimTreeFocus<CR>") -- toggle focus to file explorer
-- keymap.set("n", "<leader>ef", ":NvimTreeFindFile<CR>") -- find file in file explorer

-- Telescope

keymap.set("n", "<leader>ff", function()
    require("telescope.builtin").find_files()
end, { desc = "查找文件" })
keymap.set("n", "<leader>fg", function()
    require("telescope.builtin").live_grep()
end, { desc = "查找文本内容" })
keymap.set("n", "<leader>fb", function()
    require("telescope.builtin").buffers()
end, { desc = "在buffers中查找" })
keymap.set("n", "<leader>fh", function()
    require("telescope.builtin").help_tags()
end, { desc = "查找帮助文档" })
keymap.set("n", "<leader>fs", function()
    require("telescope.builtin").lsp_document_symbols()
end, { desc = "通过LSP查找文档符号" })
keymap.set("n", "<leader>fc", function()
    require("telescope.builtin").lsp_incoming_calls()
end, { desc = "通过LSP查找当前符号调用方" })
keymap.set("n", "<leader>ft", function()
    require("telescope.builtin").treesitter()
end, { desc = "查找语法树" })

keymap.set("n", "<leader>fd", function()
    require("telescope.builtin").diagnostics()
end, { desc = "查找诊断" })

-- Harpoon
keymap.set("n", "<leader>ha", require("harpoon.mark").add_file, { desc = "添加书签" })
keymap.set("n", "<leader>hh", require("harpoon.ui").toggle_quick_menu, { desc = "打开书签列表" })
keymap.set("n", "<leader>h1", function()
    require("harpoon.ui").nav_file(1)
end, { desc = "打开书签1" })
keymap.set("n", "<leader>h2", function()
    require("harpoon.ui").nav_file(2)
end, { desc = "打开书签2" })
keymap.set("n", "<leader>h3", function()
    require("harpoon.ui").nav_file(3)
end, { desc = "打开书签3" })

keymap.set("n", "<leader>h4", function()
    require("harpoon.ui").nav_file(4)
end, { desc = "打开书签4" })

keymap.set("n", "<leader>h5", function()
    require("harpoon.ui").nav_file(5)
end, { desc = "打开书签5" })

keymap.set("n", "<leader>h6", function()
    require("harpoon.ui").nav_file(6)
end, { desc = "打开书签6" })

keymap.set("n", "<leader>h7", function()
    require("harpoon.ui").nav_file(7)
end, { desc = "打开书签7" })

keymap.set("n", "<leader>h8", function()
    require("harpoon.ui").nav_file(8)
end, { desc = "打开书签8" })

keymap.set("n", "<leader>h9", function()
    require("harpoon.ui").nav_file(9)
end, { desc = "打开书签9" })

-- LSP
keymap.set("n", "lh", "<cmd>lua vim.lsp.buf.hover()<CR>", { desc = "显示悬停信息" })
keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "跳转到定义" })
keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { desc = "跳转到声明" })
keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { desc = "跳转到实现" })
keymap.set("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { desc = "跳转到类型定义" })
-- 不使用nvim原生lsp的references，使用telescope的lsp_references
-- keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { desc = "查找引用" })
keymap.set("n", "gr", "<cmd>lua require('telescope.builtin').lsp_references() <CR>", { desc = "查找引用" })
keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { desc = "显示签名帮助" })
keymap.set("n", "rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "重命名符号" })
keymap.set("n", "gf", "<cmd>lua vim.lsp.buf.format({async = true})<CR>", { desc = "格式化代码" })
keymap.set("v", "gf", "<cmd>lua vim.lsp.buf.format({async = true})<CR>", { desc = "格式化选中的代码" })
keymap.set("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", { desc = "显示代码操作" })
-- 使用telescope的的诊断
-- keymap.set("n", "<leader>gl", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "打开诊断浮动窗口" })
keymap.set("n", "gp", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { desc = "跳转到上一个诊断" })
keymap.set("n", "ge", "<cmd>lua vim.diagnostic.goto_next()<CR>", { desc = "跳转到下一个诊断" })
-- 使用telescope的文档符号
-- keymap.set("n", "<leader>tr", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", { desc = "显示文档符号" })
-- keymap.set(
--     "n",
--     "<leader>tr",
--     "<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>",
--     { desc = "显示文档符号" }
-- )

-- Debugging
keymap.set("n", "<leader>bb", function() require("dap").toggle_breakpoint() end, { desc = "调试: 切换断点" })
keymap.set("n", "<leader>eb", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, { desc = "调试: 编辑断点" })
keymap.set("n", "<leader>dc", function() require("dap").continue() end, { desc = "调试: 继续" })
keymap.set("n", "<leader>do", function() require("dap").step_over() end, { desc = "调试: 单步跳过" })
keymap.set("n", "<leader>di", function() require("dap").step_into() end, { desc = "调试: 单步进入" })
keymap.set("n", "<leader>dr", function() require("dap").repl.open() end, { desc = "调试: 打开REPL" })
keymap.set("n", "<leader>dx", function() require("dap").terminate() end, { desc = "调试: 终止" })
keymap.set("n", "<leader>raB", function() require("dap").clear_breakpoints() end, { desc = "调试: 清除所有断点" })
keymap.set("n", "<leader>pp", function() require("dapui").toggle() end, { desc = "调试: 显示执行点" })
keymap.set("n", "<leader>fr", function() require("dap").run_last() end, { desc = "调试: 强制返回" })
keymap.set("n", "<leader>fc", function() require("dap").run_to_cursor() end, { desc = "调试: 运行到光标" })
keymap.set("n", "<leader>ds", function() require("telescope").extensions.dap.frames() end, { desc = "调试: 显示帧" })
keymap.set("n", "<leader>di", function() require("telescope").extensions.dap.list_breakpoints() end, { desc = "调试: 列出断点" })
keymap.set("n", "<leader>dS", function() require("telescope").extensions.dap.variables() end, { desc = "调试: 显示变量" })
keymap.set("n", "<leader>dh", function() require("dap.ui.widgets").hover() end, { desc = "调试: 悬停显示" })
keymap.set("n", "<leader>d?", function() require("dap.ui.widgets").preview() end, { desc = "调试: 预览" })
keymap.set("n", "<leader>dc", function() require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes) end, { desc = "调试: 显示作用域" })

-- nvterm
keymap.set({ "t", "n" }, "<A-i>", function()
    require("nvterm.terminal").toggle("float")
end, { desc = "Toggle悬浮终端" })
keymap.set({ "t", "n" }, "<A-h>", function()
    require("nvterm.terminal").toggle("horizontal")
end, { desc = "Toggle水平终端" })
keymap.set({ "t", "n" }, "<A-v>", function()
    require("nvterm.terminal").toggle("vertical")
end, { desc = "Toggle垂直终端" })
-- proc
keymap.set("n", "qq", "@@", { desc = "执行宏" })

-- hop
keymap.set("n", "S", ":HopChar2<cr>", { desc = "两字符跳转" })
keymap.set("n", "s", ":HopChar1<cr>", { desc = "单字符跳转" })
keymap.set("n", "<leader>Fb", ":HopLineStart<cr>", { desc = "行首跳转" })
keymap.set("n", "<leader>Fl", ":HopVertical<cr>", { desc = "垂直跳转" })
keymap.set("n", "<leader>fw", ":HopWord<cr>", { desc = "单词跳转" })
keymap.set({ "n", "v" }, "f", function()
    vim.cmd("HopChar1CurrentLineAC")
end, { desc = "行内单字符向前跳转" })
keymap.set({ "n", "v" }, "F", function()
    vim.cmd("HopChar1CurrentLineBC")
end, { desc = "行内单字符后前跳转" })

keymap.set({ "n", "v" }, "t", function()
    vim.cmd("HopChar1CurrentLineAC")
end, { desc = "行内单字符向前跳转" })
keymap.set({ "n", "v" }, "T", function()
    vim.cmd("HopChar1CurrentLineBC")
end, { desc = "行内单字符后前跳转" })

-- copilot-chat
keymap.set({ "n", "v" }, "<leader>cp", function()
    return require("CopilotChat").toggle()
end, { desc = "切换CopilotChat" })
keymap.set({ "n", "v" }, "<leader>cx", function()
    return require("CopilotChat").reset()
end, { desc = "重置CopilotChat" })
keymap.set({ "n", "v" }, "<leader>cq", function()
    local input = vim.fn.input("Quick Chat: ")
    if input ~= "" then
        require("CopilotChat").ask(input)
    end
end, { desc = "快速聊天" })

-- Buffers
-- stylua: ignore start
local utils = require("core.utils")

keymap.set("n", "<leader>bx", function() utils.delete_buffer() end, { desc = "删除缓冲区" })
keymap.set("n", "L", ":bnext<cr>", { desc = "下一个缓冲区" })
keymap.set("n", "H", ":bprevious<cr>", { desc = "上一个缓冲区" })

-- Tab management
keymap.set("n", "<leader>tn", ":tabnew<CR>", { desc = "打开新标签页" }) -- open a new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "关闭标签页" }) -- close a tab
keymap.set("n", "<M-.>", ":tabn<CR>", { desc = "下一个标签页" }) -- next tab
keymap.set("n", "<M-,>", ":tabp<CR>", { desc = "上一个标签页" }) -- previous tab

-- Minifiles
vim.api.nvim_set_keymap("n", "<leader>ef", ":lua RevealInMiniFiles()<CR>",
  { noremap = true, silent = true, desc = "在MiniFiles中显示" })

function RevealInMiniFiles()
  local path = vim.fn.expand("%:p:h") -- 获取当前文件的目录路径
  require("mini.files").open(path)    -- 在 mini.files 中打开该目录
end

-- Python相关快捷键
-- 环境管理
keymap.set("n", "<leader>pi", ":Autoflake<CR>", { desc = "移除未使用的导入" })

-- 调试相关
keymap.set("n", "<leader>bb", function() require("dap").toggle_breakpoint() end, { desc = "调试: 切换断点" })
keymap.set("n", "<leader>eb", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, { desc = "调试: 编辑断点" })
keymap.set("n", "<leader>dc", function() require("dap").continue() end, { desc = "调试: 继续" })
keymap.set("n", "<leader>do", function() require("dap").step_over() end, { desc = "调试: 单步跳过" })
keymap.set("n", "<leader>di", function() require("dap").step_into() end, { desc = "调试: 单步进入" })
keymap.set("n", "<leader>dr", function() require("dap").repl.open() end, { desc = "调试: 打开REPL" })
keymap.set("n", "<leader>dx", function() require("dap").terminate() end, { desc = "调试: 终止" })
keymap.set("n", "<leader>raB", function() require("dap").clear_breakpoints() end, { desc = "调试: 清除所有断点" })
keymap.set("n", "<leader>pp", function() require("dapui").toggle() end, { desc = "调试: 显示执行点" })
keymap.set("n", "<leader>fr", function() require("dap").run_last() end, { desc = "调试: 强制返回" })
keymap.set("n", "<leader>fc", function() require("dap").run_to_cursor() end, { desc = "调试: 运行到光标" })
keymap.set("n", "<leader>ds", function() require("telescope").extensions.dap.frames() end, { desc = "调试: 显示帧" })
keymap.set("n", "<leader>di", function() require("telescope").extensions.dap.list_breakpoints() end, { desc = "调试: 列出断点" })
keymap.set("n", "<leader>dS", function() require("telescope").extensions.dap.variables() end, { desc = "调试: 显示变量" })
keymap.set("n", "<leader>dh", function() require("dap.ui.widgets").hover() end, { desc = "调试: 悬停显示" })
keymap.set("n", "<leader>d?", function() require("dap.ui.widgets").preview() end, { desc = "调试: 预览" })
keymap.set("n", "<leader>dc", function() require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes) end, { desc = "调试: 显示作用域" })

-- 测试相关
keymap.set("n", "<leader>rr", function() require("neotest").run.run_last() end, { desc = "测试: 运行上次" })
keymap.set("n", "<leader>rn", function() require("neotest").run.run() end, { desc = "测试: 运行当前" })
keymap.set("n", "<leader>dd", function() require("neotest").run.run_last({ strategy = "dap" }) end, { desc = "测试: 调试上次" })
keymap.set("n", "<leader>dn", function() require("neotest").run.run({ strategy = "dap" }) end, { desc = "测试: 调试当前" })
keymap.set("n", "<leader>cc", function() require("neotest").run.run_last({ strategy = "dap", coverage = true }) end, { desc = "测试: 覆盖率上次" })
keymap.set("n", "<leader>cn", function() require("neotest").run.run({ strategy = "dap", coverage = true }) end, { desc = "测试: 覆盖率当前" })
keymap.set("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "测试: 切换摘要" })

-- 重构相关
keymap.set("v", "<leader>em", function() require("refactoring").refactor("Extract Function") end, { desc = "重构: 提取方法" })
keymap.set("v", "<leader>ev", function() require("refactoring").refactor("Extract Variable") end, { desc = "重构: 提取变量" })
keymap.set("n", "<leader>ri", function() require("refactoring").refactor("Inline Variable") end, { desc = "重构: 内联变量" })
keymap.set("n", "<leader>re", function() vim.lsp.buf.rename() end, { desc = "重构: 重命名" })
keymap.set("n", "<leader>mv", function() vim.lsp.buf.code_action({ context = { only = { "refactor.move" } } }) end, { desc = "重构: 移动" })
