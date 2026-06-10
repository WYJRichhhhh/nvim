-- 「整理导入」统一入口。
--
-- 各语言整理导入的底层机制并不一样：Python(Ruff)、Go(gopls)、TS(ts_ls) 等
-- 都走 LSP 的 source.organizeImports code action；而 Java 走的是 jdtls 自己的
-- organize_imports 方法。但对使用者来说应当是一致的——同一个快捷键、同一个 desc。
--
-- 所以这里把「触发逻辑」和「键位」收敛到一处定义，各 ftplugin 只管注入：
--   - ftplugin/python.lua:  require("core.imports").setup()                       -- 默认走 LSP
--   - ftplugin/java.lua:    require("core.imports").setup(jdtls.organize_imports, bufnr)
-- 将来给 Go/TS 加手动键也只是一行 setup()，不必再各自抄一遍 code_action 调用。
local M = {}

-- 统一快捷键。改这一个常量，所有语言同步生效（这正是收敛到一处的意义）。
M.keymap = "<leader>oi"

-- 整理导入：先排序/分组，再删除无用导入。
--
-- 这是两个不同的 code action，别混为一谈：
--   - source.organizeImports：只对导入重新排序、分组，不删任何东西。
--   - source.fixAll：跑 server 的全部自动修复，对 Ruff 来说包含删除无用导入(F401)。
-- 早先这里只发 organizeImports，于是「<leader>oi 删不掉无用导入」——那不是 bug，
-- 是它字面只负责排序。要达到「整理 + 删无用」得把两者都跑一遍。
--
-- 实现上踩过两个坑，都在这里固化住，别改回去：
--
-- 1) context.diagnostics 必须是「原始 LSP 诊断」（带 data 字段），不能用
--    vim.diagnostic.get() 的 vim 格式。Ruff 的 fixAll 要靠每条诊断的 data 来判断修哪些；
--    传 vim 格式（无 data）它会认为「没有可修的」，直接返回空 action。原始 LSP 诊断
--    被 nvim 存在每条诊断的 user_data.lsp 里。
--
-- 2) Ruff 返回的 fixAll action 是「未 resolve」的（只有 title，没 edit），必须再发一次
--    codeAction/resolve 才拿得到真正的编辑。organizeImports 通常直接带 edit，但统一走
--    resolve 分支也安全。
--
-- 还有：两步必须「串行」。code_action 是异步的（请求→响应→apply），连发两次会让 fixAll
-- 基于排序前的旧文本，与 organizeImports 的编辑互相覆盖。所以这里按「请求→resolve→
-- apply→下一步」严格串起来。某个 server 不提供该 kind 时返回空，自动跳过（gopls /
-- ts_ls 无 fixAll 即如此，无副作用）。

local ORGANIZE_SEQUENCE = { "source.organizeImports", "source.fixAll" }

-- 取当前 buffer 的「原始 LSP 诊断」（带 data 字段，fixAll 需要它）。
-- nvim 把每条诊断对应的原始 LSP 对象存在 user_data.lsp 里；没有的（非 LSP 来源）跳过。
local function lsp_diagnostics(bufnr)
    local out = {}
    for _, d in ipairs(vim.diagnostic.get(bufnr)) do
        if d.user_data and d.user_data.lsp then
            out[#out + 1] = d.user_data.lsp
        end
    end
    return out
end

-- 对单个 client 顺序执行一串 code action kind。
local function run_kinds_for_client(client, bufnr, kinds, idx)
    idx = idx or 1
    local kind = kinds[idx]
    if not kind then
        return
    end
    local function next_step()
        run_kinds_for_client(client, bufnr, kinds, idx + 1)
    end

    local offset_encoding = client.offset_encoding or "utf-16"
    -- 用整个文档范围，确保覆盖到所有可修复诊断（按光标位置取窄 range 会漏掉别处的无用导入）。
    local last = vim.api.nvim_buf_line_count(bufnr)
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        range = { start = { line = 0, character = 0 }, ["end"] = { line = last, character = 0 } },
        context = { only = { kind }, diagnostics = lsp_diagnostics(bufnr) },
    }

    client:request("textDocument/codeAction", params, function(_, result)
        if not result or vim.tbl_isempty(result) then
            return next_step()
        end
        local action = result[1] -- only=单一 kind，取首个即可

        local function apply_and_continue(resolved)
            if resolved.edit then
                vim.lsp.util.apply_workspace_edit(resolved.edit, offset_encoding)
            end
            if resolved.command then
                local cmd = type(resolved.command) == "table" and resolved.command or resolved
                client:request("workspace/executeCommand", {
                    command = cmd.command,
                    arguments = cmd.arguments,
                }, next_step, bufnr)
            else
                next_step()
            end
        end

        -- 见上注释坑(2)：未 resolve 的 action 只有 title，要 resolve 一次才拿到 edit。
        if action.edit or action.command then
            apply_and_continue(action)
        elseif client:supports_method("codeAction/resolve") then
            client:request("codeAction/resolve", action, function(_, resolved)
                apply_and_continue(resolved or action)
            end, bufnr)
        else
            next_step()
        end
    end, bufnr)
end

-- 适用于任何提供这些 action 的 server（Ruff / gopls / ts_ls …）。
function M.via_lsp_code_action()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })
    for _, client in ipairs(clients) do
        run_kinds_for_client(client, bufnr, ORGANIZE_SEQUENCE)
    end
end

--- 在指定 buffer 上把统一快捷键绑成「整理导入」。
--- @param handler? function 触发函数；不传则默认用 LSP code action。
---        有专有方法的语言（如 Java 的 jdtls.organize_imports）在此传入自己的。
--- @param bufnr? integer 目标 buffer；不传则作用于当前 buffer。
function M.setup(handler, bufnr)
    vim.keymap.set("n", M.keymap, handler or M.via_lsp_code_action, {
        buffer = bufnr or true,
        silent = true,
        desc = "整理导入",
    })
end

return M
