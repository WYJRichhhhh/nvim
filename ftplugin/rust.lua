local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set(
  "n",
  "<leader>a",
  function()
    vim.cmd.RustLsp('codeAction') -- 走 rust-analyzer，code action 会按类别分组
    -- 不想要分组的话，也可以改用 vim.lsp.buf.codeAction()
  end,
  { silent = true, buffer = bufnr }
)
