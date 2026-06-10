-- 这些快捷键只在 go buffer 内生效（ftplugin 的作用）。

-- 整理导入：统一走 core.imports（默认 LSP source.organizeImports，由 gopls 提供）。
-- 保存时 conform 已用 goimports-reviser 自动整理；这里提供同一个 <leader>oi 手动键，
-- 与 Python / Java 保持一致的肌肉记忆。
require("core.imports").setup()
