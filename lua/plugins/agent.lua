-- 优先加载同级独立仓库；其他机器由 lazy.nvim 从 GitHub 安装。
local sibling = vim.fs.normalize(vim.fn.stdpath("config") .. "/../agent.nvim")
return {
    "WYJRichhhhh/agent.nvim",
    dir = vim.fn.isdirectory(sibling) == 1 and sibling or nil,
    main = "agent",
    cmd = { "Agent" },
    keys = {
        {
            "<leader>aa",
            function()
                require("agent").focus()
            end,
            desc = "打开或聚焦 AI Agent",
        },
        {
            "<M-a>",
            function()
                require("agent").focus()
            end,
            mode = { "n", "t" },
            desc = "唤起/隐藏 AI Agent",
        },
        { "<M-e>", "<cmd>Agent editor<CR>", mode = { "n", "t" }, desc = "返回代码窗口（保留 Agent）" },
        { "<leader>as", "<cmd>Agent select<CR>", desc = "切换 AI Agent 后端" },
        { "<leader>ar", "<cmd>Agent changes<CR>", desc = "搜索 Agent 会话修改（预览差异）" },
        { "<leader>al", "<cmd>Agent locations<CR>", desc = "Agent 讲解位置列表" },
        { "<leader>ac", "<cmd>Agent clear<CR>", desc = "清除 Agent 讲解高亮" },
        { "<leader>ad", "<cmd>Agent diff<CR>", desc = "Agent 整轮修改对比" },
        { "<leader>ag", "<cmd>Agent gitdiff<CR>", desc = "选择 worktree 查看 Git 差异" },
        { "<leader>aD", "<cmd>Agent filediff<CR>", desc = "Agent 当前文件修改对比" },
        { "<leader>af", "<cmd>Agent follow<CR>", desc = "开启/暂停跟随 Agent 修改" },
        { "<leader>ae", "<cmd>Agent code<CR>", desc = "聚焦 Agent 讲解或修改的代码" },
        { "<leader>ah", "<cmd>Agent turns<CR>", desc = "Agent 历史修改轮次" },
        { "<leader>an", "<cmd>Agent next<CR>", desc = "Agent 下一处讲解/修改" },
        { "<leader>ap", "<cmd>Agent prev<CR>", desc = "Agent 上一处讲解/修改" },
    },
    opts = {
        backend = "auto",
        terminal = { hide_key = "<M-a>" },
        -- 保留原生 TUI：Codex 使用 App Server，Claude 使用会话级 Hooks。
        codex = { enabled = true },
        claude = { enabled = true },
        window = { layout = "right", width = 0.42 },
        review = { follow = true },
    },
}
