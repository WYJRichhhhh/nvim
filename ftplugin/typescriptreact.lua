-- 这些快捷键只在该 buffer 内生效（ftplugin 的作用）。

-- 整理导入：统一走 core.imports（默认 LSP source.organizeImports，由 ts_ls 提供）。
-- 与 Python / Java / Go 共用同一个 <leader>oi，保持一致的肌肉记忆。
require("core.imports").setup()
