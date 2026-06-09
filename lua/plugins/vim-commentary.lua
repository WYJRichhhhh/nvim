-- 注释/取消注释代码行
-- return {
--   -- https://github.com/tpope/vim-commentary
--   'tpope/vim-commentary',
--   event = 'VeryLazy',
-- }

return {
    "numToStr/Comment.nvim",
    config = function()
        require("Comment").setup()
    end,
}
