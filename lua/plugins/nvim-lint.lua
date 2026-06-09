-- General purpose linters
return {
  -- https://github.com/mfussenegger/nvim-lint
  'mfussenegger/nvim-lint',
  event = 'BufWritePost',
  config = function ()
    -- Python 的 lint 已交给 Ruff LSP（见 nvim-lspconfig.lua），
    -- 这里不再用 pylint，避免重复诊断、也省去在每个 uv 项目里装 pylint。
    -- 如需对其它语言加 linter，按 filetype 添加即可。
    require('lint').linters_by_ft = {}

    -- Automatically run linters after saving.
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })
  end
}
