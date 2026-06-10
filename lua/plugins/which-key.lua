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
        -- 分组标签：为语义一致的前缀命名（对应 core/keymaps.lua 顶部「准则三」的命名空间表）。
        -- 调试键已统一收敛到 <leader>d（含 dt* 调试测试子类），故直接标为「调试」。
        -- <leader>c 实为 diff/合并(cc/cj/ck/cn/cp) + Mason(cm)，混用，标为 Diff/Mason。
        -- <leader>e 兼有 minifiles(ef) 与 Java 重构-提取(ev/ec/em)，buffer 内才出现，统标「重构/文件」。
        wk.add({
            mode = { "n", "v" },
            { "<leader>c", group = "Diff/Mason" },
            { "<leader>d", group = "调试" },
            { "<leader>e", group = "重构/文件" },
            { "<leader>f", group = "查找" },
            { "<leader>F", group = "跳转(Hop)" },
            { "<leader>g", group = "Git" },
            { "<leader>h", group = "书签(Harpoon)" },
            { "<leader>n", group = "通知" },
            { "<leader>o", group = "整理(导入)" },
            { "<leader>s", group = "窗口" },
            { "<leader>t", group = "标签页/切换" },
            { "<leader>w", group = "保存" },
        })
    end,
}
