-- chat whith ollama 

return {
    "charlie-xing/codeshell_gen",
    opts = {
        -- model = "deepseek-coder:6.7b", -- The default model to use.
        model = "codeshell", -- The default model to use.
        display_mode = "float", -- The display mode. Can be "float" or "split".
        show_prompt = false, -- Shows the Prompt submitted to Ollama.
        show_model = false, -- Displays which model you are using at the beginning of your chat session.
        no_auto_close = false, -- Never closes the window automatically.
        --init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
        -- Function to initialize Ollama
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
        -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
        -- This can also be a lua function returning a command string, with options as the input parameter.
        -- The executed command must return a JSON object with { response, context }
        -- (context property is optional).
        list_models = '<omitted lua function>', -- Retrieves a list of model names
        debug = false -- Prints errors and the command which is run.
    }
}
