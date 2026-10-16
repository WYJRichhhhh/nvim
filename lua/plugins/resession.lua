-- 用于nvim的会话管理插件
return {
    "stevearc/resession.nvim",
    lazy = false,
    config = function()
        local resession = require("resession")
        resession.setup({})
        -- 无界面启动用于检查和脚本，不应覆盖日常编辑会话。
        if #vim.api.nvim_list_uis() == 0 then
            return
        end
        vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
                -- 仅在不带任何参数启动 nvim 时才自动加载会话
                if vim.fn.argc(-1) == 0 then
                    -- 存到以 cwd 命名的另一处目录，避免污染手动保存的会话
                    resession.load(vim.fn.getcwd(), { silence_errors = true })
                end
            end,
            nested = true,
        })
        vim.api.nvim_create_autocmd("VimLeavePre", {
            callback = function()
                resession.save(vim.fn.getcwd(), { notify = true })
            end,
        })
    end,
}
