-- 全角标点的「无缝匹配」支持 —— 单一事实来源。
--
-- 背景:中文注释里大量用全角标点(，。（）【】"" '' 等),但我们在 normal 模式用的是
-- 原生 ASCII 键盘、不开中文输入法。于是 `df,` 按下的半角 `,`(U+002C)命不中注释里的
-- 全角 `，`(U+FF0C),改注释极别扭。这里让半角键在 Vim 动作里「同时认全角和半角」。
--
-- 全/半角对应表只此一份。A 层(本文件的 f/F/t/T)、B 层(mini.ai 文本对象)、
-- C 层(nvim-surround)都 require 这里的表,绝不各自再抄一份(见 CLAUDE.md「同一件事
-- 只在一个地方配」)。

local M = {}

-- f/t 跳转用:半角键 -> 它额外能匹配的全角字符**列表**。
-- 多数标点一对一(逗号/句号…),但引号一个半角键对应左右两个全角孪生
-- (' -> ' ' / " -> " "),所以值统一用列表,A 层与 hop 都遍历它。
-- 引号用 Unicode 转义写,免得源码里出现裸的全角引号、看不清是哪一个。
M.ft = {
    [","] = { "，" },
    ["."] = { "。" },
    [";"] = { "；" },
    [":"] = { "：" },
    ["?"] = { "？" },
    ["!"] = { "！" },
    ["("] = { "（" },
    [")"] = { "）" },
    ["["] = { "【" },
    ["]"] = { "】" },
    ["<"] = { "《" },
    [">"] = { "》" },
    ["'"] = { "\u{2018}", "\u{2019}" }, -- ‘ ’
    ['"'] = { "\u{201C}", "\u{201D}" }, -- “ ”
}

-- 配对(文本对象 / surround)用:半角键 -> { 全角左, 全角右 }。
-- 引号用 Unicode 转义写,免得源码里出现裸的全角引号、看不清是哪一个。
M.pairs = {
    ["("] = { "（", "）" },
    ["["] = { "【", "】" },
    ["<"] = { "《", "》" },
    ['"'] = { "\u{201C}", "\u{201D}" }, -- “ ”
    ["'"] = { "\u{2018}", "\u{2019}" }, -- ‘ ’
}

-- A 层核心:把半角键「翻译」成行内真实存在的那个字符,再交给原生 f/F/t/T。
--
-- 为什么是「翻译 + 交还原生 f」而不是自己实现跳转:这样能白嫖原生 f 的全部语义——
-- inclusive(df 含目标)、till(t 落在目标前一格)、count(2df,)、以及 d/c/y 等任意
-- operator 的组合,我们只负责回答「这个半角键此刻应当匹配行内的哪个字符」。
--
-- 已知局限:`count>=2` 且同一行混排同种全/半角标点(如 `a，b,c` 上按 2df,)会数错——
-- 因为我们翻译成单一字符后,原生 f 数的是「第 N 个该字符」而非「第 N 个标点」。
-- 试过 count-aware 的精确版(按字符类找第 N 个再换算),反而引入回归且更复杂,不值得。
-- count=1(最常用)永远正确;上述场景在中文注释里极罕见,故留作已知限制。
--
-- @param dir "f"|"F"|"t"|"T" 方向键本身
-- @param key string 用户按下的目标键(半角)
-- @return string 行内应当匹配的真实字符(半角键无全角对应时原样返回)
local function resolve(dir, key)
    local fulls = M.ft[key]
    if not fulls then
        return key -- 没有全角孪生,保持原生单字符行为
    end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] -- 0-based 字节列
    local forward = (dir == "f" or dir == "t")

    -- 前向(f/t)只看光标之后、后向(F/T)只看光标之前,与原生 f/F 的搜索范围一致。
    local seg = forward and line:sub(col + 2) or line:sub(1, col)

    -- 在片段里找某字符「最靠近光标」的位置:前向取最左命中,后向取最右命中。
    local function nearest(s)
        if forward then
            return seg:find(s, 1, true)
        end
        local last, from = nil, 1
        while true do
            local p = seg:find(s, from, true)
            if not p then
                break
            end
            last, from = p, p + 1
        end
        return last
    end

    -- 候选 = 半角键本身 + 它的所有全角孪生;取整体最靠近光标的那个字符。
    -- 前向选位置最小、后向选位置最大;不同字符不会落在同一字节位置,无需处理 tie。
    local best_char, best_pos
    local function consider(ch)
        local p = nearest(ch)
        if not p then
            return
        end
        if not best_pos or (forward and p < best_pos) or (not forward and p > best_pos) then
            best_pos, best_char = p, ch
        end
    end
    consider(key)
    for _, full in ipairs(fulls) do
        consider(full)
    end

    -- 都没命中时随便返回半角,原生 f 会自然失败(无副作用)。
    return best_char or key
end

-- 给 hop 用:把半角键构造成「半角 或 全角…」的正则,让 hop 的行内跳转同时命中它们。
-- 纯函数、不依赖 hop——keymaps.lua 的 n/v 层 f/F 拿它喂给 hop.hint_patterns。
-- 与 A 层共用同一张 M.ft 表(单一事实来源)。
--
-- 转义清单与 hop 自己的 plain_search 一致(\/.$^~[]),这样半角元字符(. [ 等)
-- 被当字面量;全角标点不在清单里,escape 后原样,无害。无全角孪生时只返回转义后的键。
--
-- @param key string 用户按下的目标键(半角)
-- @return string 可直接交给 hop.hint_patterns 的 magic 模式正则
function M.hop_pattern(key)
    local esc_chars = [[\/.$^~[]]
    local parts = { vim.fn.escape(key, esc_chars) }
    for _, full in ipairs(M.ft[key] or {}) do
        parts[#parts + 1] = vim.fn.escape(full, esc_chars)
    end
    if #parts == 1 then
        return parts[1] -- 没有全角孪生,只搜半角
    end
    for i, p in ipairs(parts) do
        parts[i] = "\\(" .. p .. "\\)"
    end
    return table.concat(parts, "\\|")
end

-- 注册 A 层映射(增强原生 f/F/t/T 的全角匹配)。按模式分两类挂,与 hop 不抢键:
--   f/F —— n/v 模式已交给 hop 行内标签跳转(见 core/keymaps.lua),故这里只补
--          operator-pending(`o`):df, / cf。 之类依赖原生 f 的 operator 语义。
--   t/T —— 不接 hop(hop 标签跳转给不了 till「落在目标前一格」),全程原生,故 n/x/o
--          三模式都增强:普通移动、可视选择、dt(/ct" 都能兼认全角。
-- expr 返回 `dir .. 真实字符`,等价于用户直接按原生 f<那个字符>,各模式行为天然一致。
function M.setup()
    local function bind(modes, dir)
        vim.keymap.set(modes, dir, function()
            local key = vim.fn.getcharstr() -- 读 f/t 后用户按的目标键
            return dir .. resolve(dir, key)
        end, { expr = true, desc = "f/t 跳转(半角键兼匹配全角标点)" })
    end
    bind("o", "f")
    bind("o", "F")
    bind({ "n", "x", "o" }, "t")
    bind({ "n", "x", "o" }, "T")
end

return M
