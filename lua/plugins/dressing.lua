-- 用于美化ui
return {
  "stevearc/dressing.nvim",
  event = "BufRead",
  opts = {
    input = {
      insert_only = false,
      start_in_insert = false,
      mappings = { i = { ["<C-c>"] = false } },
      -- 允许「按调用」覆盖输入框初始模式。dressing 的单次 opts 默认不参与配置合并,
      -- 唯一的按调用入口就是这个 get_config(见 :help dressing_get_config)。
      -- 这里只在调用方显式传了 start_mode 时才覆盖,其余所有 vim.ui.input 仍用上面的
      -- 全局默认(normal)。claude_chat 的提问框需要开在 insert,否则 IME 中文不回显。
      get_config = function(opts)
        if opts.start_mode then
          return { start_mode = opts.start_mode }
        end
      end,
    },
  },
}
