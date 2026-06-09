local keymap = vim.keymap
-- 这些快捷键只在 python buffer 内生效（ftplugin 的作用）。

-- 整理导入：交给 Ruff 的 source.organizeImports code action 处理
-- （pyright 那边我们已用 disableOrganizeImports 关掉，避免两个来源打架）。
keymap.set("n", "<leader>go", function()
    vim.lsp.buf.code_action({
        context = { only = { "source.organizeImports" }, diagnostics = {} },
        apply = true,
    })
end, { buffer = true, desc = "整理导入 (Ruff)" })

-- 调试当前测试类 / 测试方法（基于光标位置，由 nvim-dap-python 提供）。
keymap.set("n", "<leader>tc", function()
    require("dap-python").test_class()
end, { buffer = true, desc = "调试当前测试类" })

keymap.set("n", "<leader>tm", function()
    require("dap-python").test_method()
end, { buffer = true, desc = "调试当前测试方法" })
