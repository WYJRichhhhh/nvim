-- 自动补全 / 代码片段
return {
    -- https://github.com/hrsh7th/nvim-cmp
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        -- 代码片段引擎及配套的 nvim-cmp 来源
        -- https://github.com/L3MON4D3/LuaSnip
        "L3MON4D3/LuaSnip",
        -- https://github.com/saadparwaiz1/cmp_luasnip
        "saadparwaiz1/cmp_luasnip",

        -- LSP 补全能力
        -- https://github.com/hrsh7th/cmp-nvim-lsp
        "hrsh7th/cmp-nvim-lsp",

        -- 额外的常用代码片段
        -- https://github.com/rafamadriz/friendly-snippets
        "rafamadriz/friendly-snippets",
        "onsails/lspkind.nvim",
        -- https://github.com/hrsh7th/cmp-buffer
        "hrsh7th/cmp-buffer",
        -- https://github.com/hrsh7th/cmp-path
        "hrsh7th/cmp-path",
        -- https://github.com/hrsh7th/cmp-cmdline
        "hrsh7th/cmp-cmdline",
    },
    config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        local lspkind = require("lspkind")
        require("luasnip.loaders.from_vscode").lazy_load()
        luasnip.config.setup({})

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            completion = {
                completeopt = "menu,menuone,noinsert",
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-j>"] = cmp.mapping.select_next_item(), -- 下一个候选项
                ["<C-k>"] = cmp.mapping.select_prev_item(), -- 上一个候选项
                ["<C-d>"] = cmp.mapping.scroll_docs(-4), -- 文档向上滚动
                ["<C-f>"] = cmp.mapping.scroll_docs(4), -- 文档向下滚动
                ["<C-Space>"] = cmp.mapping.complete({}), -- 显示补全候选
                ["<CR>"] = cmp.mapping.confirm({
                    behavior = cmp.ConfirmBehavior.Replace,
                    select = true,
                }),
                -- 在候选项间切换；若有片段处于激活状态，则 Tab 跳到下一个占位参数
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_locally_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                -- 反向在候选项间切换；若有片段处于激活状态，则跳到上一个占位参数
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.locally_jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
            }),
            sources = cmp.config.sources({
                { name = "nvim_lsp" }, -- LSP
                { name = "luasnip" }, -- 代码片段
                { name = "buffer" }, -- 当前缓冲区内的文本
                { name = "path" }, -- 文件系统路径
            }),
            window = {
                -- 给补全弹窗加上边框
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            formatting = {
                format = lspkind.cmp_format({
                    with_text = true,
                    maxwidth = 50,
                    before = function(entry, vim_item)
                        vim_item.menu = "[" .. string.upper(entry.source.name) .. "]"
                        return vim_item
                    end,
                }),
            },
        })
    end,
}
