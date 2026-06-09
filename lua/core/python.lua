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
    return vim.fs.root(path, M.root_markers) or vim.fs.dirname(path)
end

--- 为给定的项目根解析出应当使用的 Python 解释器。
--- 优先级：显式激活的 venv -> 项目内的 .venv（uv 默认）-> PATH 上的 python3
--- @param root? string 项目根
--- @return string python 绝对路径，或 "python3"
function M.venv_python(root)
    -- 1. 你手动激活过的 venv 永远优先（说明这是你刻意指定的）。
    local activated = vim.env.VIRTUAL_ENV
    if activated and activated ~= "" then
        return vim.fs.joinpath(activated, "bin", "python")
    end
    -- 2. uv（以及 `python -m venv`）会在项目根下创建 .venv。
    if root then
        local venv = vim.fs.joinpath(root, ".venv", "bin", "python")
        if vim.uv.fs_stat(venv) then
            return venv
        end
    end
    -- 3. 兜底：PATH 上的 python3。
    local sys = vim.fn.exepath("python3")
    return sys ~= "" and sys or "python3"
end

return M
