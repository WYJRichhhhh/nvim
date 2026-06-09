-- 行内调试变量文本
return {
  -- https://github.com/theHamsta/nvim-dap-virtual-text
  'theHamsta/nvim-dap-virtual-text',
  lazy = true,
  opts = {
    -- 以注释样式展示调试文本，避免与真实代码混淆
    commented = true,
    -- 自定义虚拟文本：inline 位置只显示值，否则显示「变量名 = 值」
    display_callback = function(variable, buf, stackframe, node, options)
      if options.virt_text_pos == 'inline' then
        return ' = ' .. variable.value
      else
        return variable.name .. ' = ' .. variable.value
      end
    end,
  }
}

