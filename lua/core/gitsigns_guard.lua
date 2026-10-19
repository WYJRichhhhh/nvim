-- A removed worktree can leave a loaded buffer and queued blame jobs behind.
local M = {}

local function missing_directory(path)
    if type(path) ~= "string" or path == "" then
        return false
    end
    local stat, _, code = vim.uv.fs_stat(path)
    return (stat and stat.type ~= "directory") or (not stat and (code == "ENOENT" or code == "ENOTDIR"))
end

function M.detach_missing(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    local status = vim.b[buf].gitsigns_status_dict
    if status and (missing_directory(status.root) or missing_directory(status.gitdir)) then
        local gs = package.loaded.gitsigns
        if gs then
            gs.detach(buf)
        end
    end
end

function M.setup()
    -- Install before gitsigns.setup: its async Git module captures this function.
    -- Keep the workaround scoped to Gitsigns; do not replace global vim.system.
    local system = require("gitsigns.system")
    if not system._worktree_guard then
        system._worktree_guard = true
        local original = system.system
        system.system = function(cmd, opts, on_exit)
            local ok, result = pcall(original, cmd, opts, on_exit)
            if ok then
                return result
            end
            if cmd[1] ~= "git" or not opts or not missing_directory(opts.cwd) then
                error(result, 0)
            end
            -- The directory may disappear between an event check and process spawn.
            -- Let Git report a normal failure instead of throwing out of a coroutine.
            local parent = vim.fs.dirname(opts.cwd)
            while missing_directory(parent) and parent ~= vim.fs.dirname(parent) do
                parent = vim.fs.dirname(parent)
            end
            local command = { "git", "-C", opts.cwd }
            vim.list_extend(command, vim.list_slice(cmd, 2))
            local callback = on_exit
                and function(completed)
                    -- A removed root is expected here; avoid a second blame notification.
                    completed.stderr = ""
                    on_exit(completed)
                end
            return original(command, vim.tbl_extend("force", opts, { cwd = parent }), callback)
        end
    end
    local group = vim.api.nvim_create_augroup("GitsignsWorktreeGuard", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "CursorMoved", "CursorHold", "WinResized" }, {
        group = group,
        callback = function(event)
            M.detach_missing(event.buf)
        end,
        desc = "Detach Gitsigns from removed worktrees without closing buffers",
    })
    vim.api.nvim_create_autocmd("FocusGained", {
        group = group,
        callback = function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                M.detach_missing(buf)
            end
        end,
    })
end

return M
