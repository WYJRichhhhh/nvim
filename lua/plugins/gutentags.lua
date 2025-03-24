-- gutentags配置
return {
  {
    "ludovicchabant/vim-gutentags",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- 设置ctags可执行文件路径
      vim.g.gutentags_ctags_executable = "ctags"
      
      -- 设置项目根目录标记文件
      vim.g.gutentags_project_root = { ".git", "setup.py", "pyproject.toml", "requirements.txt" }
      
      -- 设置ctags额外参数
      vim.g.gutentags_ctags_extra_args = {
        "--fields=+l",  -- 包含语言信息
        "--languages=Python",  -- 只处理Python文件
        "--Python-kinds=-i",  -- 不包含导入
        "--Python-kinds=+c",  -- 包含类
        "--Python-kinds=+f",  -- 包含函数
        "--Python-kinds=+m",  -- 包含方法
        "--Python-kinds=+v",  -- 包含变量
        "--Python-kinds=+l",  -- 包含局部变量
        "--Python-kinds=+d",  -- 包含装饰器
      }
      
      -- 设置自动生成标签
      vim.g.gutentags_generate_on_new = true
      vim.g.gutentags_generate_on_missing = true
      vim.g.gutentags_generate_on_write = true
      
      -- 设置标签文件位置
      vim.g.gutentags_ctags_tagfile = ".tags"
      
      -- 设置缓存目录
      vim.g.gutentags_cache_dir = vim.fn.expand("~/.cache/nvim/ctags/")
      
      -- 确保缓存目录存在
      vim.fn.mkdir(vim.g.gutentags_cache_dir, "p")
      
      -- 设置调试信息
      vim.g.gutentags_debug = false
      
      -- 设置自动加载标签
      vim.g.gutentags_auto_add_gtags_cscope = 0
      
      -- 设置标签生成命令
      vim.g.gutentags_ctags_tagfile = ".tags"
      vim.g.gutentags_ctags_postprocess_cmd = "ctags --sort=yes --fields=+l"
      
      -- 设置快捷键
      vim.keymap.set("n", "<leader>gt", ":GutentagsUpdate<CR>", { desc = "更新标签" })
      vim.keymap.set("n", "<leader>gT", ":GutentagsToggleEnabled<CR>", { desc = "切换标签生成" })
    end,
  },
} 