local M = {}

--- 获取指定高亮组的前景色和背景色，如果不存在使用fallback
--- @param name string 高亮组名称
--- @param fallback? table 找不到时回退使用的高亮属性
--- @return table properties # 高亮组属性
function M.get_hlgroup(name, fallback)
    if vim.fn.hlexists(name) == 1 then
        local group = vim.api.nvim_get_hl(0, { name = name })

        local hl = {
            fg = group.fg == nil and "NONE" or M.parse_hex(group.fg),
            bg = group.bg == nil and "NONE" or M.parse_hex(group.bg),
        }

        return hl
    end
    return fallback or {}
end

--- 删除指定编号的缓冲区，且不影响窗口布局
--- @param buf? number 要删除的缓冲区编号
function M.delete_buffer(buf)
    if buf == nil or buf == 0 then
        buf = vim.api.nvim_get_current_buf()
    end
    local win_id = vim.fn.bufwinid(buf)
    local alt_buf = vim.fn.bufnr("#")
    if alt_buf ~= buf and vim.fn.buflisted(buf) == 1 and alt_buf ~= -1 then
        vim.api.nvim_win_set_buf(win_id, alt_buf)
        vim.api.nvim_command("bwipeout " .. buf)
        return
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    local has_prev_buf = pcall(vim.cmd, "bprevious")
    if has_prev_buf and buf ~= vim.api.nvim_win_get_buf(win_id) then
        vim.api.nvim_command("bwipeout " .. buf)
        return
    end

    -- 备用缓冲区和上一个缓冲区都不可用时，新建一个空缓冲区顶上
    local new_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win_id, new_buf)
    vim.api.nvim_command("bwipeout " .. buf)
end

--- 切换到上一个缓冲区
function M.switch_to_other_buffer()
    -- 优先切到备用缓冲区
    local ok, _ = pcall(function()
        vim.cmd("buffer #")
    end)
    if ok then
        return
    end

    -- 退而求其次，切到上一个缓冲区
    if M.get_buffer_count() > 1 then
        vim.cmd("bprevious")
        return
    end

    vim.notify("No other buffer to switch to!", 3, { title = "Warning" })
end

--- 获取打开的缓冲区数量
--- @return number
function M.get_buffer_count()
    local count = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.fn.bufname(buf) ~= "" then
            count = count + 1
        end
    end
    return count
end

--- 把整数表示的颜色转成十六进制字符串
--- @param int_color number
function M.parse_hex(int_color)
    return string.format("#%x", int_color)
end

--- 创建一个相对屏幕尺寸居中的浮动窗口
--- @param width number 窗口宽度，1 表示占满屏幕宽度
--- @param height number 窗口高度，取值 0 到 1 之间
--- @param buf number 缓冲区编号
--- @return number 窗口编号
function M.open_centered_float(width, height, buf)
    buf = buf or vim.api.nvim_create_buf(false, true)
    local win_width = math.floor(vim.o.columns * width)
    local win_height = math.floor(vim.o.lines * height)
    local offset_y = math.floor((vim.o.lines - win_height) / 2)
    local offset_x = math.floor((vim.o.columns - win_width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = offset_y,
        col = offset_x,
        style = "minimal",
        border = "single",
    })

    return win
end

--- 在浮动窗口中打开帮助窗口
--- @param buf number 缓冲区编号
function M.open_help(buf)
    if
        buf ~= nil and vim.bo[buf].filetype == "help"
        or (vim.bo[buf].filetype == "markdown" and not vim.bo[buf].modifiable)
    then
        local help_win = vim.api.nvim_get_current_win()
        local new_win = M.open_centered_float(0.6, 0.7, buf)

        -- 同步滚动位置
        vim.wo[help_win].scroll = vim.wo[new_win].scroll

        -- 关闭原来的帮助窗口
        vim.api.nvim_win_close(help_win, true)
    end
end

--- 执行一条 shell 命令并返回输出
--- @param cmd table 要执行的命令，格式为 { "command", "arg1", "arg2", ... }
--- @param cwd? string 工作目录
--- @return table stdout, number? return_code, table? stderr
function M.get_cmd_output(cmd, cwd)
    if type(cmd) ~= "table" then
        vim.notify("Command must be a table", 3, { title = "Error" })
        return {}
    end

    local command = table.remove(cmd, 1)
    local stderr = {}
    local stdout, ret = require("plenary.job")
        :new({
            command = command,
            args = cmd,
            cwd = cwd,
            on_stderr = function(_, data)
                table.insert(stderr, data)
            end,
        })
        :sync()

    return stdout, ret, stderr
end

--- 把若干行文本写入文件
--- @param file string 文件路径
--- @param lines table 要写入文件的行列表
function M.write_to_file(file, lines)
    if not lines or #lines == 0 then
        return
    end
    local buf = io.open(file, "w")
    for _, line in ipairs(lines) do
        if buf ~= nil then
            buf:write(line .. "\n")
        end
    end

    if buf ~= nil then
        buf:close()
    end
end

--- 显示当前缓冲区与指定文件之间的 diff
--- @param file string 用来与当前缓冲区比对的文件
function M.diff_file(file)
    local pos = vim.fn.getpos(".")
    local current_file = vim.fn.expand("%:p")
    vim.cmd("edit " .. file)
    vim.cmd("vert diffsplit " .. current_file)
    vim.fn.setpos(".", pos)
end

--- 显示某次提交里的文件与当前缓冲区之间的 diff
--- @param commit string 提交哈希
--- @param file_path string 文件路径
function M.diff_file_from_history(commit, file_path)
    local extension = vim.fn.fnamemodify(file_path, ":e") == "" and "" or "." .. vim.fn.fnamemodify(file_path, ":e")
    local temp_file_path = os.tmpname() .. extension

    local cmd = { "git", "show", commit .. ":" .. file_path }
    local out = M.get_cmd_output(cmd)

    M.write_to_file(temp_file_path, out)
    M.diff_file(temp_file_path)
end

--- 打开一个 telescope picker，选择文件与当前缓冲区比对
--- @param recent? boolean 为 true 时打开最近文件 picker
function M.telescope_diff_file(recent)
    local picker = require("telescope.builtin").find_files
    if recent then
        picker = require("telescope.builtin").oldfiles
    end

    picker({
        prompt_title = "Select File to Compare",
        attach_mappings = function(prompt_bufnr)
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                M.diff_file(selection.value)
            end)
            return true
        end,
    })
end

--- 打开一个 telescope picker，选择某次提交与当前缓冲区比对
function M.telescope_diff_from_history()
    local current_file = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:."):gsub("\\", "/")
    require("telescope.builtin").git_commits({
        git_command = { "git", "log", "--pretty=oneline", "--abbrev-commit", "--follow", "--", current_file },
        attach_mappings = function(prompt_bufnr)
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                M.diff_file_from_history(selection.value, current_file)
            end)
            return true
        end,
    })
end

--- 在 toggleterm 中运行当前文件
function M.run_shell_script()
    local script = vim.fn.expand("%:p")
    require("toggleterm").exec(script)
end

return M
