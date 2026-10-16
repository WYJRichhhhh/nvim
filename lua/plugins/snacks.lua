-- 只启用输入框和终端，继续使用现有的搜索、通知和文件管理配置。
local layouts = {
    { "<A-i>", 1, { position = "float", width = 0.8, height = 0.8, border = "rounded" }, "切换浮动终端" },
    { "<A-h>", 2, { position = "bottom", height = 0.3 }, "切换水平终端" },
    { "<A-v>", 3, { position = "right", width = 0.5 }, "切换垂直终端" },
}
local keys = {}
for _, layout in ipairs(layouts) do
    keys[#keys + 1] = {
        layout[1],
        function()
            -- 独立编号使三种布局各自保留终端进程，不会互相切换错窗口。
            require("snacks").terminal.toggle(nil, { count = layout[2], win = layout[3] })
        end,
        mode = { "n", "t" },
        desc = layout[4],
    }
end
return {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    keys = keys,
    opts = {
        -- 输入框直接进入插入模式，中文输入和重命名都可以立即输入。
        input = { enabled = true, win = { border = "rounded" } },
        terminal = { enabled = true },
    },
}
