-- 全角标点的「无缝匹配」支持 —— 单一事实来源。
--
-- 背景:中文注释里大量用全角标点(，。（）【】 等),但我们在 normal 模式用的是原生
-- ASCII 键盘、不开中文输入法。于是 `df,` 按下的半角 `,`(U+002C) 命不中注释里的全角
-- `，`(U+FF0C),改注释极别扭。这里让半角键在 Vim 动作里「同时认全角和半角」。
--
-- 全/半角对应表只此一份。A 层(本文件的 f/F/t/T)、B 层(mini.ai 文本对象)、
-- C 层(nvim-surround)都 require 这里的表,绝不各自再抄一份(见 CLAUDE.md「同一件事
-- 只在一个地方配」)。

local M = {}

-- f/t 跳转用:半角键 -> 它额外能匹配的那个全角字符(都是单字符标点)。
M.ft = {
    [","] = "，",
    ["."] = "。",
    [";"] = "；",
    [":"] = "：",
    ["?"] = "？",
    ["!"] = "！",
    ["("] = "（",
    [")"] = "）",
    ["["] = "【",
    ["]"] = "】",
    ["<"] = "《",
    [">"] = "》",
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
    local full = M.ft[key]
    if not full then
        return key -- 没有全角孪生,保持原生单字符行为
    end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] -- 0-based 字节列
    local forward = (dir == "f" or dir == "t")

    -- 前向(f/t)只看光标之后、后向(F/T)只看光标之前,与原生 f/F 的搜索范围一致。
    local seg = forward and line:sub(col + 2) or line:sub(1, col)

    -- 在片段里找半角/全角各自「最靠近光标」的位置:前向取最左命中,后向取最右命中。
    local function nearest(pat)
        if forward then
            return seg:find(pat, 1, true)
        end
        local last, from = nil, 1
        while true do
            local p = seg:find(pat, from, true)
            if not p then
                break
            end
            last, from = p, p + 1
        end
        return last
    end

    local i_half = nearest(key)
    local i_full = nearest(full)
    if i_half and i_full then
        -- 两个都在:前向谁更靠左、后向谁更靠右,就匹配谁。
        if forward then
            return i_half <= i_full and key or full
        end
        return i_half >= i_full and key or full
    end
    -- 只命中其一,就用那个;两个都没有时随便返回哪个,原生 f 都会自然失败(无副作用)。
    return i_full and full or key
end

-- 注册 A 层映射。只挂 operator-pending(`o`)模式:
-- 纯 normal/visual 的 f/F/t/T 已被 hop 接管(见 core/keymaps.lua),那是行内高亮跳转、
-- 另一套交互;痛点(df, 之类)全部落在 operator-pending 的原生 f,这里只增强它,
-- 与 hop 的 n/v 映射天然隔离、零冲突。
function M.setup()
    for _, dir in ipairs({ "f", "F", "t", "T" }) do
        vim.keymap.set("o", dir, function()
            local key = vim.fn.getcharstr() -- 读 operator 后用户按的目标键
            return dir .. resolve(dir, key)
        end, { expr = true, desc = "f/t 跳转(半角键兼匹配全角标点)" })
    end
end

return M
