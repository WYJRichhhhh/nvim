-- 对话
return {
  "CopilotC-Nvim/CopilotChat.nvim",
  branch = "canary",
  cmd = "CopilotChat",
  config = function()
    -- TODO: add blink.cmp integration when/if it's available
    -- require("CopilotChat.integrations.cmp").setup()
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "copilot-chat",
      callback = function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
      end,
    })

    require("CopilotChat").setup({
      model = "gpt-4",
      auto_insert_mode = true,
      show_help = false,
      show_folds = false,
      question_header = "  Scott ",
      answer_header = "  Copilot ",
      window = {
        layout = "float",
        width = 0.6,
        height = 0.7,
        border = "rounded",
      },
      mappings = {
        close = {
          normal = "q",
        },
      },
      selection = function(source)
        local select = require("CopilotChat.select")
        return select.visual(source) or select.buffer(source)
      end,
    })
  end,
}
