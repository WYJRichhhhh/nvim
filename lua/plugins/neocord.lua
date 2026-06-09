-- 用于将nvim的状态显示到Discord上
return {
    "IogaMaster/neocord",
    event = "VeryLazy",
    config = function()
        require("neocord").setup({
            editing_text = function(_)
                local ft = vim.bo.filetype
                if ft == "" then
                    return "Editing a file"
                end
                return "Editing a " .. ft .. " file"
            end,

            workspace_text = function(project_name)
                if project_name == nil then
                    return "💻 Just chilling"
                end

                local git_origin = vim.system({ "git", "config", "--get", "remote.origin.url" }):wait()

                -- 只展示自己拥有或 fork 的项目，否则视为不便公开的内容
                if string.find(git_origin.stdout, "scottmckendry") ~= nil then
                    return "Working on " .. project_name:gsub("%a", string.upper, 1) .. " 🚀"
                end

                return "Working on a private project 🤫"
            end,
        })
    end,
}

