-- 配对文本对象(i/a)同时认全角与半角 —— B 层。
--
-- mini.ai 提供 ci( di[ ca" 这类「改/删/选 配对内外」的文本对象。这里把最常用的几个
-- 半角触发键扩成「ASCII 配对 或 对应全角配对」二选一,于是光标在中文注释的全角
-- （…）【…】“…” 里时,ci( di[ ca" 照样命中;而原生 ASCII 行为(含括号内侧留白裁剪)
-- 一字不改。全/半角对应表只取自 core/cjk_punct.lua,不在此另抄(见 CLAUDE.md)。
--
-- 实现要点:custom_textobjects['('] 会「完全覆盖」内置 '(',所以必须把内置 ASCII 分支
-- 也一并写回,再追加全角分支。mini.ai 的 composed pattern 允许「单个匹配位放多条备选
-- 子模式」,每条会被独立展开(见其 cartesian_product),正好用来表达「ASCII 或 全角」。
--
-- 已知取舍:
--   * ASCII 分支用 %b 走平衡匹配,支持嵌套((a(b)c) 等);全角分支用非平衡最短匹配
--     （().-()）,因全角字符多字节、%b 只认单字节。故「嵌套的全角括号」不被识别——
--     这在中文注释里极罕见,可接受。
--   * 全角分支不裁内侧留白(（ x ）的 i 会含空格),ASCII 括号分支仍裁,与内置一致。
return {
    -- https://github.com/echasnovski/mini.ai
    "echasnovski/mini.ai",
    event = "VeryLazy",
    opts = function()
        local punct = require("core.cjk_punct")

        -- ASCII 配对键 -> 它的右半边(用于拼 %bXY 平衡模式)。这是通用 ASCII 配对常识,
        -- 与「全/半角对应」是两码事,故就近放这儿,不进 cjk_punct。
        local ascii_close = {
            ["("] = ")",
            ["["] = "]",
            ["<"] = ">",
            ['"'] = '"',
            ["'"] = "'",
        }
        -- 括号类(开括号)裁内侧留白,引号类不裁 —— 复刻 mini.ai 内置语义。
        local is_bracket = { ["("] = true, ["["] = true, ["<"] = true }

        -- 为某个半角键构造「ASCII 或 全角」的 composed 文本对象 spec。
        local function spec(half, full_pair)
            local hl, hr = half, ascii_close[half]
            local fl, fr = vim.pesc(full_pair[1]), vim.pesc(full_pair[2])

            -- ASCII 分支:%b 平衡匹配 + 内置同款提取模板(括号裁留白、引号不裁)。
            local extract = is_bracket[half] and "^.%s*().-()%s*.$" or "^.().*().$"
            local ascii = { "%b" .. hl .. hr, extract }

            -- 全角分支:非平衡最短匹配,两个空捕获组界定 i 文本对象。
            local full = { fl .. "().-()" .. fr }

            -- 外层再包一层 {} 表示「单个匹配位」,内含两条互为备选的子模式。
            return { { ascii, full } }
        end

        local custom = {}
        for half, full_pair in pairs(punct.pairs) do
            custom[half] = spec(half, full_pair)
        end

        return { custom_textobjects = custom }
    end,
}
