-- Markdown specific settings
vim.opt.wrap = true -- Wrap text
vim.opt.breakindent = true -- Match indent on line break
vim.opt.linebreak = true -- Line break on whole words
vim.opt.tabstop = 2 -- Tab size
vim.opt.shiftwidth = 2
-- Allow j/k when navigating wrapped lines
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- Spell check
-- vim.opt.spelllang = 'en_us'
-- vim.opt.spell = true
