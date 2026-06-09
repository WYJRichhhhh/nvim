-- REST 客户端
return {
    -- https://github.com/diepm/vim-rest-console
    "diepm/vim-rest-console",
    event = "VeryLazy",
    config = function()
        -- 关闭插件自带的默认按键映射
        vim.g.vrc_set_default_mapping = 0
        -- 响应默认按 JSON 解析
        vim.g.vrc_response_default_content_type = "application/json"
        -- 输出缓冲区名（用 .json 后缀以触发语法高亮）
        vim.g.vrc_output_buffer_name = "_OUTPUT.json"
        -- 对响应缓冲区执行格式化命令
        vim.g.vrc_auto_format_response_patterns = {
            json = "jq",
        }
    end,
}
