local keymap = vim.keymap
-- 这些快捷键只在 python buffer 内生效（ftplugin 的作用）。

-- 整理导入：统一走 core.imports（默认 LSP source.organizeImports，由 Ruff 提供）。
-- pyright 那边已用 disableOrganizeImports 关掉，避免两个来源打架。
require("core.imports").setup()

-- 调试当前测试类 / 测试方法（基于光标位置，由 nvim-dap-python 提供）。
-- 归到调试命名空间 <leader>d 下的 dt(debug-test) 子类：dtc=测试类、dtm=测试方法。
-- buffer-local，只在 python buffer 生效；Java 用同一套键位（见 ftplugin/java.lua）以保持一致。
keymap.set("n", "<leader>dtc", function()
    require("dap-python").test_class()
end, { buffer = true, desc = "调试: 当前测试类" })

keymap.set("n", "<leader>dtm", function()
    require("dap-python").test_method()
end, { buffer = true, desc = "调试: 当前测试方法" })
