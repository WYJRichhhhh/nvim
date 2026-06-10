local jdtls = require("jdtls")

-- 机器特定的本地覆盖（JDK 安装路径因机而异，无法自动探测）。
-- 不存在时退回空表，下面各处再优雅降级到 PATH / 默认值。见 lua/local.lua.example。
local ok_local, local_cfg = pcall(require, "local")
local java_local = (ok_local and type(local_cfg) == "table" and local_cfg.java) or {}

local mason = vim.fn.stdpath("data") .. "/mason"

-- jdtls 的 config 目录按 OS + CPU 架构区分（config_mac_arm / config_mac / config_linux / config_win）。
-- 写死成 config_mac_arm 会让 Linux / Intel mac 上直接起不来，这里据运行平台自动选。
local function jdtls_config_dir()
    local os_name = jit.os -- "OSX" | "Linux" | "Windows"
    if os_name == "OSX" then
        return mason .. (jit.arch == "arm64" and "/packages/jdtls/config_mac_arm" or "/packages/jdtls/config_mac")
    elseif os_name == "Windows" then
        return mason .. "/packages/jdtls/config_win"
    end
    return mason .. "/packages/jdtls/config_linux"
end

-- launcher jar 的版本号会随 jdtls 升级变化，写死路径迟早失效，用 glob 取实际文件。
local function jdtls_launcher_jar()
    return vim.fn.glob(mason .. "/share/jdtls/plugins/org.eclipse.equinox.launcher_*.jar")
end

-- 获取当前项目的名称
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
-- 设置工作区目录
-- vim.env.Home 找到的是用户目录
local workspace_dir = vim.env.HOME .. "/jdtls-workspace/" .. project_name
-- 调试所需的java包,vim.fn.glob用于去文件系统中匹配模式
local bundles = {
    -- java-debug-adapter 的版本号同样会变，用 glob 匹配避免写死。
    vim.fn.glob(
        mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
        1
    ),
}

-- 创建 keymap 的辅助函数
local function nnoremap(rhs, lhs, bufopts, desc)
    bufopts.desc = desc
    vim.keymap.set("n", rhs, lhs, bufopts)
end
-- 运行/调试单元测试所需
-- vim.list_extend(bundles, vim.split(vim.fn.glob(vim.env.HOME .. "/dev/java/vscode-java-test/server/*.jar", 1), "\n"))
vim.list_extend(
    bundles,
    vim.split(
        vim.fn.glob(mason .. "/packages/java-test/extension/server/*.jar", 1),
        "\n"
    )
)

-- 查看 `:help vim.lsp.start_client` 的帮助文档，了解支持的 config 选项
local config = {
    -- 启动语言服务器的命令
    -- 参见: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
    cmd = {
        -- 使用jenv执行java，这样可以切换不同的java版本
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-javaagent:" .. mason .. "/share/jdtls/lombok.jar", -- 启动lombok支持
        "-Xmx4g", -- 设置最大堆内存为4G
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",

        -- Eclipse jdtls 所在位置
        "-jar",
        -- 自编译路径 /dev/java/eclipse.jdt.ls/org.eclipse.jdt.ls.product/target/repository/plugins/org.eclipse.equinox.launcher_1.6.900.v20240613-2009.jar

        jdtls_launcher_jar(),
        -- config 目录按运行平台自动选择（见顶部 jdtls_config_dir）。
        "-configuration",
        jdtls_config_dir(),
        "-data",
        workspace_dir,
    },

    -- 若未提供，将使用默认值，每个独特的root_dir都会启动一个专用的LSP服务器和客户端
    root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "pom.xml", "build.gradle" }),

    -- 此处可以配置Eclipse jdt.ls的特定配置
    -- 参见 https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
    settings = {
        java = {
            -- 主 JDK（需 17+）。优先用本机 local.lua 指定的路径；没配就退回
            -- $JAVA_HOME / PATH 上的 java 所在 JDK，让 jdtls 自己定位，避免写死。
            home = java_local.jdk_home,
            eclipse = {
                -- 启用下载源码
                downloadSources = true,
            },
            configuration = {
                updateBuildConfiguration = "interactive",
                -- 多版本运行时同样来自 local.lua（因机而异）。未配置则为空表，
                -- jdtls 直接用上面的 home / 系统默认 java。
                runtimes = java_local.runtimes or {},
            },
            maven = {
                -- 启用maven源码下载
                downloadSources = true,
            },
            implementationsCodeLens = {
                --启用代码透镜以显示实现
                enabled = true,
            },
            referencesCodeLens = {
                -- 启用代码透镜以显示引用
                enabled = true,
            },
            references = {
                -- 包含反编译的源代码
                includeDecompiledSources = true,
            },
            -- 启用签名帮助
            signatureHelp = { enabled = true },
            format = {
                -- 启用代码格式化
                enabled = true,
                -- 默认即可格式化；如有需要，也可指定特定的文件/URL 作为格式化规范
                -- settings = {
                --   url = "https://github.com/google/styleguide/blob/gh-pages/intellij-java-google-style.xml",
                --   profile = "GoogleStyle",
                -- },
            },
        },
        completion = {
            favoriteStaticMembers = { -- 常用静态成员
                "org.hamcrest.MatcherAssert.assertThat",
                "org.hamcrest.Matchers.*",
                "org.hamcrest.CoreMatchers.*",
                "org.junit.jupiter.api.Assertions.*",
                "java.util.Objects.requireNonNull",
                "java.util.Objects.requireNonNullElse",
                "org.mockito.Mockito.*",
            },
            importOrder = { -- 导入顺序
                "java",
                "javax",
                "com",
                "org",
            },
        },
        extendedClientCapabilities = jdtls.extendedClientCapabilities,
        sources = {
            organizeImports = {
                starThreshold = 9999,
                staticStarThreshold = 9999,
            },
        },
        codeGeneration = {
            toString = {
                template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
            },
            useBlocks = true, -- 使用代码块
        },
    },
    -- 需要启动带有方法签名和占位符的自动补全,这里使用blink.cmp插件的能力，也可以使用cmp_nvim_lsp的能力，看你安装了哪个插件
    -- capabilities = require("blink.cmp").get_lsp_capabilities(),
    capabilities = require("cmp_nvim_lsp").capabilities,
    flags = {
        allow_incremental_sync = true, -- 启用增量同步
    },
    init_options = {
        -- 引用上面定义的bundles以支持调试和单元测试
        bundles = bundles,
    },
    -- 调试所需
    on_attach = function(client, bufnr)
        jdtls.setup_dap({ hotcodereplace = "auto" }) -- 配置dap调试
        -- require("dap.ext.vscode").load_launchjs() -- 加载launch.json
        require("jdtls.dap").setup_dap_main_class_configs()
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        -- nvim-jdtls 额外提供的一些方法
        -- 整理导入：统一走 core.imports（键位常量在那里定义），Java 传入 jdtls 专有方法。
        require("core.imports").setup(jdtls.organize_imports, bufnr)
        -- 重构-提取（jdtls 专有，buffer-local）。统一用 <leader> 写法（= <space>，但全仓统一）。
        -- e=extract 子命名空间：ev 变量 / ec 常量 / em 方法。
        nnoremap("<leader>ev", jdtls.extract_variable, bufopts, "重构: 提取变量")
        nnoremap("<leader>ec", jdtls.extract_constant, bufopts, "重构: 提取常量")
        vim.keymap.set(
            "v",
            "<leader>em",
            [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
            { noremap = true, silent = true, buffer = bufnr, desc = "重构: 提取方法" }
        )
        -- 调试当前测试类 / 测试方法。统一到调试命名空间 <leader>d 下的 dt(debug-test) 子类，
        -- 与 Python(ftplugin/python.lua) 用同一套键位：dtc=测试类、dtm=测试方法。
        nnoremap("<leader>dtc", jdtls.test_class, bufopts, "调试: 当前测试类")
        nnoremap("<leader>dtm", jdtls.test_nearest_method, bufopts, "调试: 当前测试方法")
    end,
}

-- 启用一个新的客户端和服务器，或基于root_dir附加到已有的客户端和服务器
jdtls.start_or_attach(config)
