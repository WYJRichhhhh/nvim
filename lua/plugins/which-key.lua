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
            { "<leader>a", group = "AI(claude)" },
            { "<leader>c", group = "Diff/Mason" },
            { "<leader>d", group = "调试" },
            { "<leader>e", group = "重构/文件" },
            { "<leader>f", group = "查找" },
            { "<leader>F", group = "跳转(Hop)" },
            { "<leader>g", group = "Git" },
            { "<leader>n", group = "通知" },
            { "<leader>o", group = "整理(导入)" },
            { "<leader>s", group = "窗口" },
            { "<leader>t", group = "标签页/切换" },
            { "<leader>w", group = "保存" },
            { "<leader>y", group = "复制路径" },
        })

        -- 修补「关掉 Flog(gl)/blame(gb) 等辅助窗后 which-key 不再弹提示」的竞争。
        -- which-key 的提示靠它在每个 buffer 局部挂的 <space> 触发键（动作键本身是全局的，
        -- 所以快捷键照常能用、只是没提示了）。它在执行动作前会先摘掉当前 buffer 的触发键、
        -- 再靠 libuv 定时器异步补挂；而补挂只在 BufEnter 时按缓存 Mode 进行、不强制重建。
        -- 于是「焦点切回代码 buffer」和「定时器补挂」存在竞争，关掉独占 tab/浮窗时易踩中，
        -- 落点 buffer 的触发键就丢了。这里在关窗/关标签页后强制重挂一次，把这条缝补严。
        vim.api.nvim_create_autocmd({ "WinClosed", "TabClosed" }, {
            group = vim.api.nvim_create_augroup("wk_reattach_after_close", { clear = true }),
            callback = function()
                -- schedule 到焦点稳定后再重挂；update=true 会重建 Mode 并重新 attach 触发键。
                vim.schedule(function()
                    pcall(function() require("which-key.buf").get({ update = true }) end)
                end)
            end,
        })
    end,
}
