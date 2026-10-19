-- Run: nvim --headless -n -i NONE -u NONE -l tests/gitsigns_worktree.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/gitsigns.nvim")
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
temp = vim.uv.fs_realpath(temp)
local work = temp .. "/work"
local function git(...)
    local result = vim.system({ "git", "-C", temp, ... }, { text = true }):wait()
    assert(result.code == 0, result.stderr)
end
local errors = {}
vim.notify = function(message, level)
    if level == vim.log.levels.ERROR then
        errors[#errors + 1] = message
    end
end
local guard = require("core.gitsigns_guard")
local ok, err = xpcall(function()
    git("init", "-q")
    git("config", "user.name", "Test")
    git("config", "user.email", "test@example.invalid")
    vim.fn.writefile({ "before", "second line" }, temp .. "/sample.txt")
    git("add", ".")
    git("commit", "-qm", "base")
    git("worktree", "add", "-qb", "review", work)
    local unguarded = require("gitsigns.system").system
    guard.setup()
    local gs = require("gitsigns")
    gs.setup({ current_line_blame = true, current_line_blame_opts = { delay = 50 } })
    vim.cmd.edit(work .. "/sample.txt")
    local source = vim.api.nvim_get_current_buf()
    assert(
        vim.wait(5000, function()
            return vim.b[source].gitsigns_status_dict ~= nil
        end),
        "not attached"
    )
    -- Keep an unsaved buffer while a CLI removes the worktree on disk.
    vim.api.nvim_buf_set_lines(source, 0, 1, false, { "unsaved local content" })
    git("worktree", "remove", "--force", work)
    assert(vim.fn.isdirectory(work) == 0)
    local spawned, spawn_error = pcall(unguarded, { "git", "status" }, { cwd = work }, function() end)
    assert(not spawned and tostring(spawn_error):find("cwd", 1, true), "original failure not reproduced")
    -- Exercise the queued-command race before any window event can detach it.
    local result
    require("gitsigns.system").system({ "git", "status" }, { cwd = work }, function(value)
        result = value
    end)
    assert(vim.wait(2000, function()
        return result ~= nil
    end))
    assert(result.code ~= 0 and result.stderr == "")
    local agent = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(agent, true, { relative = "editor", row = 0, col = 0, width = 30, height = 5 })
    vim.api.nvim_win_close(0, true)
    vim.api.nvim_exec_autocmds("BufEnter", { buffer = source })
    vim.wait(200, function()
        return false
    end)
    assert(not vim.b[source].gitsigns_status_dict, "removed worktree still attached")
    assert(vim.bo[source].modified)
    assert(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "unsaved local content")
    -- An ordinary repository must keep signs and normal Git failures visible.
    vim.cmd.edit(temp .. "/sample.txt")
    local normal = vim.api.nvim_get_current_buf()
    assert(vim.wait(5000, function()
        return vim.b[normal].gitsigns_status_dict ~= nil
    end))
    guard.detach_missing(normal)
    assert(vim.b[normal].gitsigns_status_dict)
    local failure
    require("gitsigns.system").system({ "git", "not-a-real-command" }, { cwd = temp }, function(value)
        failure = value
    end)
    assert(vim.wait(2000, function()
        return failure ~= nil
    end))
    assert(failure.code ~= 0 and failure.stderr ~= "")
    assert(#errors == 0, table.concat(errors, "\n"))
    print(
        "GITSIGNS_WORKTREE_OK removed cwd / queued spawn / toggle / unsaved buffer / normal repo / real errors preserved"
    )
end, debug.traceback)
pcall(function()
    require("gitsigns").detach_all()
end)
vim.fn.delete(temp, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd.cquit(1)
end
vim.cmd("qa!")
