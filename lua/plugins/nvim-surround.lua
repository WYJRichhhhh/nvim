-- 增删改包围字符。
--
-- 默认 ys/cs/ds 作用在 ASCII 配对上;这里额外注册两个触发键,让 surround 也能操作
-- 最常用的全角配对(全/半角对应表见 core/cjk_punct.lua,这里只取需要的两项):
--   P (Paren) -> 全角括号 （）
--   Q (Quote) -> 全角双引号 “”
-- 选大写 P/Q 是因为它们在 surround 的 key 空间里空闲,且不与原生 ( " 及现有
-- aliases(q 已是引号别名)冲突。例:ysiwP 用全角括号包住单词、dsP 删除、cs(P 把半角
-- 括号换成全角。
return {
    -- https://github.com/kylechui/nvim-surround
    "kylechui/nvim-surround",
    version = "*", -- 锁稳定版；想用最新特性可去掉此项改跟 `main` 分支
    event = "VeryLazy",
    opts = function()
        local punct = require("core.cjk_punct")

        -- 由「{左, 右}」全角配对生成一个 surround 项:复用上面的对应表,find/delete
        -- 都按字节匹配多字节字符,nvim-surround 内部的 adjust_selection 会自动把选区
        -- 修正到完整字符边界,所以这里直接 pesc 全角字符即可。
        local function make(pair)
            local left, right = pair[1], pair[2]
            local l, r = vim.pesc(left), vim.pesc(right)
            return {
                add = { { left }, { right } },
                find = function()
                    return require("nvim-surround.config").get_selection({
                        pattern = l .. ".-" .. r,
                    })
                end,
                delete = "^(" .. l .. ")().-(" .. r .. ")()$",
            }
        end

        return {
            surrounds = {
                ["P"] = make(punct.pairs["("]), -- 全角 （）
                ["Q"] = make(punct.pairs['"']), -- 全角 “”
            },
        }
    end,
}
