-- 自动补全括号 / 引号等成对符号
return {
  -- https://github.com/windwp/nvim-autopairs
  'windwp/nvim-autopairs',
  event = "InsertEnter",
  opts = {
    check_ts = true, -- 启用 treesitter 判断上下文
    ts_config = {
      lua = { "string" }, -- 在 lua 字符串节点内不自动补全成对符号
      javascript = { "template_string" }, -- 在 javascript 模板字符串内不自动补全成对符号
    }
  }
}
