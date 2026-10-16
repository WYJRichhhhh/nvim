return {
    "echasnovski/mini.files",
    dependencies = { "echasnovski/mini.icons" },
    -- 双击空格打开文件管理器
    keys = {
        {
            "<leader><leader>",
            function()
                local path = vim.bo.buftype ~= "nofile" and vim.api.nvim_buf_get_name(0) or nil
                require("mini.files").open(path)
            end,
            desc = "Open mini.files (cwd)",
        },
    },
    config = function()
        local MiniFiles = require("mini.files")
        MiniFiles.setup({
            -- 窗口大小
            windows = {
                width_focus = 60,
                width_nofocus = 40,
            },
        })

        local nsMiniFiles = vim.api.nvim_create_namespace("mini_files_git")
        local autocmd = vim.api.nvim_create_autocmd

        autocmd("User", {
            group = vim.api.nvim_create_augroup("MiniFiles_SetCwd", { clear = true }),
            pattern = "MiniFilesBufferCreate",
            callback = function(ev)
                vim.keymap.set("n", "g=", function()
                    -- 取当前面板目录而非光标下的子项，空目录也可以作为工作目录。
                    local state = MiniFiles.get_explorer_state()
                    local path = state and state.branch[state.depth_focus]
                    if not path or vim.fn.isdirectory(path) == 0 then
                        return
                    end
                    -- 先正常关闭，未同步的文件操作仍由 mini.files 提示处理。
                    if MiniFiles.close() == false then
                        return
                    end
                    -- :cd 改全局目录，并以新根重新打开，避免沿用旧的父级面板和历史分支。
                    vim.cmd.cd({ args = { path } })
                    MiniFiles.open(path, false)
                    vim.notify("工作目录已切换：" .. vim.fn.getcwd(), vim.log.levels.INFO)
                end, { buffer = ev.data.buf_id, desc = "切换工作目录并重定位资源面板" })
            end,
        })

        -- git 状态缓存
        local gitStatusCache = {}
        local cacheTimeout = 2000 -- 缓存有效期（毫秒）

        local function mapSymbols(status)
            local statusMap = {
                [" M"] = { symbol = "", hlGroup = "MiniDiffSignChange" }, -- 工作区已修改
                ["M "] = { symbol = "", hlGroup = "MiniDiffSignAdd" }, -- 暂存区已修改
                ["MM"] = { symbol = "", hlGroup = "MiniDiffSignChange" }, -- 工作区和暂存区都已修改
                ["A "] = { symbol = "", hlGroup = "MiniDiffSignAdd" }, -- 已加入暂存区的新文件
                ["AA"] = { symbol = "≈", hlGroup = "MiniDiffSignAdd" }, -- 工作区和暂存区都新增
                ["D "] = { symbol = "-", hlGroup = "MiniDiffSignDelete" }, -- 从暂存区删除
                ["AM"] = { symbol = "⊕", hlGroup = "MiniDiffSignChange" }, -- 工作区新增、暂存区已修改
                ["AD"] = { symbol = "-•", hlGroup = "MiniDiffSignChange" }, -- 暂存区新增、工作区已删除
                ["R "] = { symbol = "→", hlGroup = "MiniDiffSignChange" }, -- 暂存区重命名
                ["U "] = { symbol = "‖", hlGroup = "MiniDiffSignChange" }, -- 未合并路径
                ["UU"] = { symbol = "⇄", hlGroup = "MiniDiffSignAdd" }, -- 文件未合并
                ["UA"] = { symbol = "⊕", hlGroup = "MiniDiffSignAdd" }, -- 文件未合并且在工作区新增
                ["??"] = { symbol = "", hlGroup = "MiniDiffSignDelete" }, -- 未跟踪文件
                ["!!"] = { symbol = "", hlGroup = "MiniDiffSignChange" }, -- 被忽略的文件
            }

            local result = statusMap[status] or { symbol = "?", hlGroup = "NonText" }
            return result.symbol, result.hlGroup
        end

        ---@param cwd string
        ---@param callback function
        -- 获取git状态
        local function fetchGitStatus(cwd, callback)
            local function on_exit(content)
                if content.code == 0 then
                    callback(content.stdout)
                    vim.g.content = content.stdout
                end
            end
            vim.system({ "git", "status", "--ignored", "--porcelain" }, { text = true, cwd = cwd }, on_exit)
        end

        local function escapePattern(str)
            return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        end

        -- 更新minifiles的git状态
        local function updateMiniWithGit(buf_id, gitStatusMap)
            vim.schedule(function()
                -- 切换根目录会关闭旧面板，异步 Git 结果可能在关闭后才返回。
                if not vim.api.nvim_buf_is_valid(buf_id) then
                    return
                end
                local nlines = vim.api.nvim_buf_line_count(buf_id)
                local cwd = vim.fn.getcwd()
                local escapedcwd = escapePattern(cwd)
                if vim.fn.has("win32") == 1 then
                    escapedcwd = escapedcwd:gsub("\\", "/")
                end

                for i = 1, nlines do
                    local entry = MiniFiles.get_fs_entry(buf_id, i)
                    if not entry then
                        break
                    end
                    local relativePath = entry.path:gsub("^" .. escapedcwd .. "/", "")
                    local status = gitStatusMap[relativePath]

                    if status then
                        local symbol, hlGroup = mapSymbols(status)
                        vim.api.nvim_buf_set_extmark(buf_id, nsMiniFiles, i - 1, 0, {
                            sign_text = symbol,
                            sign_hl_group = hlGroup,
                            priority = 2,
                        })
                    else
                    end
                end
            end)
        end

        -- 判断是否是git仓库
        local function is_valid_git_repo()
            if vim.fn.isdirectory(".git") == 0 then
                return false
            end
            return true
        end

        -- git状态解析
        local function parseGitStatus(content)
            local gitStatusMap = {}
            -- 用 lua match 比 vim.split 更快（个人经验）
            for line in content:gmatch("[^\r\n]+") do
                local status, filePath = string.match(line, "^(..)%s+(.*)")
                -- 把文件路径按 / 拆成各级
                local parts = {}
                for part in filePath:gmatch("[^/]+") do
                    table.insert(parts, part)
                end
                -- 从根目录开始逐级拼
                local currentKey = ""
                for i, part in ipairs(parts) do
                    if i > 1 then
                        -- 用分隔符把各级拼起来，得到唯一的 key
                        currentKey = currentKey .. "/" .. part
                    else
                        currentKey = part
                    end
                    -- 如果是最后一级，说明是文件，连同它的状态一起记录
                    if i == #parts then
                        gitStatusMap[currentKey] = status
                    else
                        -- 否则是目录：还没记录过就补上
                        if not gitStatusMap[currentKey] then
                            gitStatusMap[currentKey] = status
                        end
                    end
                end
            end
            return gitStatusMap
        end

        local function updateGitStatus(buf_id)
            if not is_valid_git_repo() then
                return
            end
            -- 必须用 getcwd()：本事件触发时当前 buffer 已是 mini.files 的特殊缓冲
            -- （名字形如 minifiles://...），expand("%:p:h") 会取到这个 URI 而非真实目录，
            -- 传给 git 的 cwd 就 ENOENT。且相对路径计算、.git 判断、缓存 key 本就以 getcwd 为准。
            local cwd = vim.fn.getcwd()
            local currentTime = os.time()
            if gitStatusCache[cwd] and currentTime - gitStatusCache[cwd].time < cacheTimeout then
                updateMiniWithGit(buf_id, gitStatusCache[cwd].statusMap)
            else
                fetchGitStatus(cwd, function(content)
                    local gitStatusMap = parseGitStatus(content)
                    gitStatusCache[cwd] = {
                        time = currentTime,
                        statusMap = gitStatusMap,
                    }
                    updateMiniWithGit(buf_id, gitStatusMap)
                end)
            end
        end

        local function clearCache()
            gitStatusCache = {}
        end

        local function augroup(name)
            return vim.api.nvim_create_augroup("MiniFiles_" .. name, { clear = true })
        end

        -- 自动命令，打开文件管理器时，更新git状态,关闭文件管理器时，清除缓存,更新文件管理器时，更新git状态
        autocmd("User", {
            group = augroup("start"),
            pattern = "MiniFilesExplorerOpen",
            -- pattern = { "minifiles" },
            callback = function()
                local bufnr = vim.api.nvim_get_current_buf()
                updateGitStatus(bufnr)
            end,
        })

        autocmd("User", {
            group = augroup("close"),
            pattern = "MiniFilesExplorerClose",
            callback = function()
                clearCache()
            end,
        })

        autocmd("User", {
            group = augroup("update"),
            pattern = "MiniFilesBufferUpdate",
            callback = function(sii)
                local bufnr = sii.data.buf_id
                -- 同 updateGitStatus：缓存 key 以 getcwd 为准，不能用 expand("%:p:h")
                local cwd = vim.fn.getcwd()
                if gitStatusCache[cwd] then
                    updateMiniWithGit(bufnr, gitStatusCache[cwd].statusMap)
                end
            end,
        })
    end,
}
