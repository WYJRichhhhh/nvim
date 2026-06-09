return {
  -- https://github.com/mfussenegger/nvim-dap-python
  'mfussenegger/nvim-dap-python',
  ft = 'python',
  dependencies = {
    -- https://github.com/mfussenegger/nvim-dap
    'mfussenegger/nvim-dap',
  },
  config = function ()
    -- 解释器统一走 core.python（唯一事实来源），从当前文件推断项目根再找 .venv，
    -- 不写死任何绝对路径。见 CLAUDE.md「Python 环境解析」。
    local py = require('core.python')
    require('dap-python').setup(py.venv_python(py.root()))
  end
}
