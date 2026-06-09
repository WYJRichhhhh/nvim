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
        require("mini.files").setup({
            -- 窗口大小
            windows = {
                width_focus = 60,
                width_nofocus = 40,
            },
        })

        local nsMiniFiles = vim.api.nvim_create_namespace("mini_files_git")
        local autocmd = vim.api.nvim_create_autocmd
        local _, MiniFiles = pcall(require, "mini.files")

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
            local cwd = vim.fn.expand("%:p:h")
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
                local cwd = vim.fn.expand("%:p:h")
                if gitStatusCache[cwd] then
                    updateMiniWithGit(bufnr, gitStatusCache[cwd].statusMap)
                end
            end,
        })
    end,
}
