-- 格式化整合插件，fmt on save
return {
  "stevearc/conform.nvim",
  -- 在打开文件时运行
  event = "BufReadPre",
  config = function()
    -- 全局变量
    vim.g.disable_autoformat = false
    require("conform").setup({
      -- 指定格式化表
      formatters_by_ft = {
        bicep = { "bicep" },
        css = { "prettier" },
        go = { "goimports_reviser", "gofmt", "golines" },
        html = { "prettier" },
        javascript = { "prettier" },
        json = { "prettier" },
        lua = { "stylua" },
        markdown = { "prettier" },
        nix = { "nixfmt" },
        rust = { "rustfmt" },
        scss = { "prettier" },
        sh = { "shfmt" },
        templ = { "templ" },
        toml = { "taplo" },
        yaml = { "prettier" },
      },

      -- 保存后格式化策略，如果禁用了自动格式化，则不进行格式化
      -- 如果文件类型是powershell，则使用lsp格式化
      -- 如果文件类型是其它类型，则使用fallback格式化
      format_after_save = function()
        if vim.g.disable_autoformat then
          return
        else
          if vim.bo.filetype == "ps1" then
            vim.lsp.buf.format()
            return
          end
          return { lsp_format = "fallback" }
        end
      end,

      -- 自定义格式化器
      formatters = {
        goimports_reviser = {
          command = "goimports-reviser",
          args = { "-output", "stdout", "$FILENAME" },
        },
      },
    })

    -- 覆盖 Bicep 的默认选项
    require("conform").formatters.bicep = {
      args = { "format", "--stdout", "$FILENAME", "--indent-size", "4" },
    }

    -- 覆盖 stylua 的默认选项
    require("conform").formatters.stylua = {
      prepend_args = { "--indent-type", "Spaces" },
    }

    -- 覆盖 Prettier 的默认选项
    require("conform").formatters.prettier = {
      prepend_args = { "--tab-width", "2" },
    }

    -- 创建一个nvim用户命令，用于切换格式化保存
    vim.api.nvim_create_user_command("ConformToggle", function()
      vim.g.disable_autoformat = not vim.g.disable_autoformat
      print("Conform " .. (vim.g.disable_autoformat and "disabled" or "enabled"))
    end, {
      desc = "Toggle format on save",
    })
  end,
}
