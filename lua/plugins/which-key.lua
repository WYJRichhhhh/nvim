return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
        local wk = require("which-key")
        wk.setup({
            preset = "helix",
            icons = {
                rules = false,
            },
        })
        -- 分组标签：仅为语义一致的前缀命名。
        -- 调试相关键散落在 b/d/e/p/r 多个前缀，故只把最集中的 <leader>d 标为「调试」，
        -- 其余混用前缀（b/e/p）不强行命名，避免误导。
        -- <leader>c 实为 diff/合并(cc/cj/ck/cn/cp) + Mason(cm)；
        -- <leader>gt 混了 gitsigns 切换与 gutentags 标签，不单独命名。
        wk.add({
            mode = { "n", "v" },
            { "<leader>c", group = "Diff/Mason" },
            { "<leader>d", group = "调试" },
            { "<leader>f", group = "查找" },
            { "<leader>g", group = "Git" },
            { "<leader>h", group = "书签(Harpoon)" },
            { "<leader>n", group = "通知" },
            { "<leader>s", group = "窗口" },
            { "<leader>t", group = "标签页/切换" },
            { "<leader>w", group = "保存" },
        })
    end,
}
