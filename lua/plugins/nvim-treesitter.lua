-- 语法高亮(nvim-treesitter main 分支)
--
-- 为什么用 main 分支:neovim 0.12 改了 treesitter query 的 match 格式——
-- directive/predicate handler 收到的 captures[id] 从单个 TSNode 变成了 TSNode 列表。
-- master 分支已冻结、不再适配 0.12,其 query_predicates.lua 仍按旧格式 `match[id]`
-- 取单 node,于是拿到一张 table,node:range() 报 "method 'range' (a nil value)",
-- 导致任何含代码块的 markdown(如 leader aa 的回答浮窗)一解析就崩。
-- main 是一次不兼容重写,删掉了那套自定义 directive(injections.scm 改用纯
-- (language) @injection.language 捕获),是 neovim 0.12 唯一受支持的路径。
--
-- main 相对 master 的关键差异,本文件据此改写:
--   1. 不支持 lazy-load → lazy = false(顺带让依赖它的 aerial/autopairs/ts-autotag
--      在启动后总能拿到 treesitter)
--   2. 没有 nvim-treesitter.configs.setup;高亮/缩进不再自动开,要在 FileType 时手动启用
--   3. parser 装到 stdpath('data')/site,用 install{} 按需装(已装则 no-op)
return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local ts = require("nvim-treesitter")
        -- 默认 install_dir = stdpath('data')/site,并把它前置到 runtimepath。
        ts.setup()

        -- 要确保安装的 parser。先用 get_installed() 过滤掉已装的,避免每次启动
        -- 都为全量列表起异步安装任务;install() 本身对已装语言也是 no-op。
        local ensure = {
            "bash", "bicep", "c_sharp", "gitignore", "go", "gomod", "gosum",
            "gowork", "html", "http", "json", "lua", "luadoc", "luap",
            "markdown", "markdown_inline", "nix", "odin", "powershell",
            "regex", "rust", "templ", "toml", "vimdoc", "yaml", "java",
        }
        local installed = ts.get_installed()
        local missing = vim.tbl_filter(function(lang)
            return not vim.tbl_contains(installed, lang)
        end, ensure)
        if #missing > 0 then
            ts.install(missing)
        end

        -- main 分支:高亮与缩进按 buffer 启用。仅在该 filetype 对应语言已装 parser 时
        -- 才开,否则 vim.treesitter.start() 会因缺 parser 报错。
        local function enable(buf)
            if not vim.api.nvim_buf_is_valid(buf) then
                return
            end
            local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
            -- language.add 成功返回 true,失败返回 nil(不抛错),据此判断 parser 是否可用。
            if not lang or not vim.treesitter.language.add(lang) then
                return
            end
            pcall(vim.treesitter.start, buf)
            -- treesitter 缩进(官方标注实验性);沿用迁移前 indent.enable=true 的行为。
            vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("treesitter_enable", { clear = true }),
            callback = function(ev)
                enable(ev.buf)
            end,
        })

        -- 对所有已加载 buffer 补一遍高亮。两种场景会绕开上面的 FileType autocmd:
        --   1. 因 lazy=false 在启动时加载,启动即打开的文件其 FileType 可能已先于
        --      本 autocmd 触发过;
        --   2. resession 在 VimEnter(晚于本 config)恢复会话时,直接以 ft=python
        --      载入十几个 buffer,既错过 FileType autocmd 也错过下面这次启动补扫,
        --      表现为恢复出来的文件全部不高亮(highlighter.active 为 nil)。
        local function enable_all_loaded()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) then
                    enable(buf)
                end
            end
        end

        enable_all_loaded()

        -- resession 加载完会话后会 emit User ResessionLoadPost,此时再补一遍即可
        -- 点亮恢复出来的 buffer。未装 resession 时该事件永不触发,无副作用。
        vim.api.nvim_create_autocmd("User", {
            group = "treesitter_enable",
            pattern = "ResessionLoadPost",
            callback = enable_all_loaded,
        })
    end,
}
