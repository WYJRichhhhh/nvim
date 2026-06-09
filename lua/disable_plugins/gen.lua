-- 与 ollama 对话

return {
    "charlie-xing/codeshell_gen",
    opts = {
        -- model = "deepseek-coder:6.7b", -- 默认使用的模型
        model = "codeshell", -- 默认使用的模型
        display_mode = "float", -- 显示模式，可取 "float" 或 "split"
        show_prompt = false, -- 是否显示提交给 Ollama 的 Prompt
        show_model = false, -- 是否在对话开头显示正在使用的模型
        no_auto_close = false, -- 是否从不自动关闭窗口
        --init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
        -- 初始化 Ollama 的函数
        -- command = "curl --silent --no-buffer -X POST http://localhost:11434/api/generate -d $body",
        command = "curl --silent --no-buffer -X POST http://localhost:8080/completion -d $body",
        -- command = "curl --silent --no-buffer -X POST http://192.168.3.43:18080/completion -d $body",
        model_options = {
            n_predict = 8192,
            temperature = 0.1,
            repetition_penalty = 1.2,
            top_k = 40,
            top_p = 0.95,
            stream = true,
            stop = {"|<end>|", "|end|", "<|endoftext|>", "## human"},
            system = "你的名字是X，你是一位技术娴熟的中文计算机科学家助理。你的回答应当简洁明了。如果涉及到代码或命令，直接输出答案，不做任何解释或辅助性回答。"
        },
        -- Ollama 服务对应的命令。可使用占位符 $prompt、$model 和 $body（已做 shell 转义）。
        -- 这里也可以传一个返回命令字符串的 lua 函数，入参为 options。
        -- 执行的命令必须返回一个 JSON 对象 { response, context }
        -- （context 字段可选）。
        list_models = '<omitted lua function>', -- 获取模型名称列表
        debug = false -- 打印错误信息及实际执行的命令
    }
}
