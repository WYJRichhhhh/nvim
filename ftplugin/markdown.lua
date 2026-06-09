-- Markdown 专属设置
vim.opt.wrap = true -- 自动折行
vim.opt.breakindent = true -- 折行后保持缩进对齐
vim.opt.linebreak = true -- 按完整单词折行，不从词中间断开
vim.opt.tabstop = 2 -- tab 宽度
vim.opt.shiftwidth = 2
-- 折行后让 j/k 按可视行移动，而不是按物理行跳过整段
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- 拼写检查
-- vim.opt.spelllang = 'en_us'
-- vim.opt.spell = true
