-- Python 环境解析（LSP 与 DAP 共用）。
--
-- 核心思想：从“正在编辑的文件”出发推断出“项目根”和“解释器”，
-- 而不是去信任 shell 里激活的 venv —— 在 uv 工作流下你通常不会
-- `source .venv/bin/activate`，所以 $VIRTUAL_ENV 多半是空的，
-- 旧配置因此 fallback 到系统 python，导致看不到项目依赖、满屏导入报错。
local M = {}

-- 用来识别 Python 项目根的标记，越靠前越优先。
-- uv 项目一定有 pyproject.toml（通常还有 uv.lock），优先锚定在这里，
-- 可以避免“根目录漂移到上层某个 .git”导致的导入解析错乱。
M.root_markers = {
    "pyproject.toml",
    "uv.lock",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
}

--- 找到某个 buffer / 路径所属的项目根。
--- @param bufnr_or_path? integer|string buffer 号、路径，或 nil（当前 buffer）
--- @return string root 绝对路径（找不到标记时退回文件所在目录 / cwd）
function M.root(bufnr_or_path)
    local path = bufnr_or_path
    if type(bufnr_or_path) == "number" or bufnr_or_path == nil then
        local buf = bufnr_or_path or 0
        path = vim.api.nvim_buf_get_name(buf)
    end
    if path == nil or path == "" then
        return vim.uv.cwd()
    end
    -- 按标记优先级逐项搜索，避免附近的 .git 抢过上级 pyproject.toml。
    for _, marker in ipairs(M.root_markers) do
        local root = vim.fs.root(path, marker)
        if root then
            return root
        end
    end
    return vim.fs.dirname(path)
end

--- 为给定的项目根解析出应当使用的 Python 解释器。
--- 优先项目内 .venv，再退回显式激活环境和系统 Python，避免跨项目串环境。
--- @param root? string 项目根
--- @return string python
function M.venv_python(root)
    local suffix = jit.os == "Windows" and { "Scripts", "python.exe" } or { "bin", "python" }
    local function interpreter(dir)
        if not dir or dir == "" then
            return nil
        end
        local path = vim.fs.joinpath(dir, unpack(suffix))
        return vim.fn.executable(path) == 1 and path or nil
    end
    local project = root and interpreter(vim.fs.joinpath(root, ".venv"))
    local activated = interpreter(vim.env.VIRTUAL_ENV)
    local system = vim.fn.exepath("python3")
    return project or activated or (system ~= "" and system or "python3")
end

return M
