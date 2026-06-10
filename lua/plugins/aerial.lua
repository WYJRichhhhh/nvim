-- 代码符号大纲(树状)
--
-- 为什么引入:telescope 的 lsp_document_symbols 本质是个一维模糊列表,
-- 给不出 class → method 的父子层级。aerial 专做大纲,能按 LSP/treesitter
-- 的符号树缩进折叠展示,并跟随光标高亮当前所在符号。键位在 core/keymaps.lua
-- 里(<leader>fs),与其它查找类键位聚合在一处。
--
-- 展示方式:居中浮窗(宽 0.5 高 0.7);展示全部符号(含变量/常量/字段);
-- 图标按 kind 覆盖成类 PyCharm 风格,并在 config 里按语义上色区分。
return {
    -- https://github.com/stevearc/aerial.nvim
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
    dependencies = {
        -- 符号取自 treesitter,LSP 未就绪时也能出大纲
        "nvim-treesitter/nvim-treesitter",
        -- 图标统一走 mini.icons(它已 mock nvim-web-devicons),不再单独引入
        "echasnovski/mini.icons",
    },
    opts = {
        -- 符号来源优先级:有 LSP 用 LSP,否则退回 treesitter,保证总有结果
        backends = { "lsp", "treesitter", "markdown", "man" },
        -- 居中浮窗:default_direction 走 float,宽度取自 layout(min/max_width),
        -- 其余(relative/高度/override 居中)由顶层 float 表控制。
        -- 注意:float 是 aerial 的顶层 key,和 layout 平级,放进 layout 里不生效。
        layout = {
            default_direction = "float",
            -- 浮窗宽度:固定为编辑器一半(window.lua 用 layout 的 min/max_width 算宽)
            min_width = 0.5,
            max_width = 0.5,
        },
        float = {
            border = "rounded",
            -- editor:相对整个编辑器居中
            relative = "editor",
            -- 高度上下界:最少 8 行,或编辑器高度的 0.7
            max_height = 0.7,
            min_height = { 8, 0.1 },
            override = function(conf, _source_winid)
                -- override 会被两个路径调用:初次打开时 conf 带 width/height,
                -- resize 时只带 row/col。所以宽高一律从 vim.o 自算,不读 conf.width。
                local width = math.floor(vim.o.columns * 0.5)
                local height = math.floor(vim.o.lines * 0.7)
                conf.width = width
                conf.height = height
                conf.row = math.floor((vim.o.lines - height) / 2)
                conf.col = math.floor((vim.o.columns - width) / 2)
                conf.relative = "editor"
                conf.anchor = "NW"
                return conf
            end,
        },
        -- 打开大纲后自动把光标跳进去,方便直接 j/k 浏览
        attach_mode = "global",
        -- 跟随光标:始终高亮当前符号,并自动展开其所在层级
        highlight_on_hover = true,
        show_guides = true,
        -- 展示 LSP/treesitter 返回的全部符号(含变量/常量/字段/属性等)
        filter_kind = false,
        -- 类 PyCharm 大纲图标:用 Nerd Font 里语义接近的字形按 kind 覆盖,
        -- 配合下方高亮组的配色,做到一眼区分 class/method/field/variable
        icons = {
            Array         = "󰅪 ",
            Boolean       = "◩ ",
            Class         = "󰠱 ",
            Constant      = "󰏿 ",
            Constructor   = "󰆧 ",
            Enum          = "󰕘 ",
            EnumMember    = "󰕘 ",
            Event         = "󱐋 ",
            Field         = "󰜢 ",
            File          = "󰈙 ",
            Function      = "󰊕 ",
            Interface     = "󰜰 ",
            Key           = "󰌋 ",
            Method        = "󰆧 ",
            Module        = "󰏗 ",
            Namespace     = "󰦮 ",
            Null          = "󰟢 ",
            Number        = "󰎠 ",
            Object        = "󰅩 ",
            Operator      = "󰆕 ",
            Package       = "󰏗 ",
            Property      = "󰜢 ",
            String        = "󰉿 ",
            Struct        = "󰙅 ",
            TypeParameter = "󰊄 ",
            Variable      = "󰀫 ",
            -- 折叠/展开指示符
            Collapsed     = " ",
        },
    },
    config = function(_, opts)
        require("aerial").setup(opts)

        -- 类 PyCharm 的语义配色:把不同 kind 的图标染成区分度高的颜色。
        -- aerial 的图标高亮组名为 Aerial<Kind>Icon,统一在这里集中覆盖。
        local kind_colors = {
            Class = "#e5c07b", -- 类:黄
            Struct = "#e5c07b",
            Interface = "#56b6c2", -- 接口:青
            Enum = "#56b6c2",
            EnumMember = "#56b6c2",
            Method = "#c678dd", -- 方法:紫
            Function = "#c678dd",
            Constructor = "#c678dd",
            Field = "#61afef", -- 字段/属性:蓝
            Property = "#61afef",
            Variable = "#abb2bf", -- 变量:灰
            Constant = "#d19a66", -- 常量:橙
            Module = "#98c379", -- 模块/命名空间:绿
            Namespace = "#98c379",
            Package = "#98c379",
        }
        local function apply_kind_colors()
            for kind, color in pairs(kind_colors) do
                vim.api.nvim_set_hl(0, "Aerial" .. kind .. "Icon", { fg = color })
            end
        end
        apply_kind_colors()
        -- 切换主题后重新上色,避免被新配色方案清掉
        vim.api.nvim_create_autocmd("ColorScheme", {
            callback = apply_kind_colors,
        })
    end,
}
