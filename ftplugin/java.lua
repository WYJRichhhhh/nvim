local jdtls = require("jdtls")
-- 获取当前项目的名称
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
-- 设置工作区目录
-- vim.env.Home 找到的是用户目录
local workspace_dir = vim.env.HOME .. "/jdtls-workspace/" .. project_name
print(workspace_dir)
-- 调试所需的java包,vim.fn.glob用于去文件系统中匹配模式
local bundles = {
    -- vim.fn.glob(
    --     vim.env.HOME
    --         .. "/dev/java/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.53.1.jar"
    -- ),
    vim.fn.glob(
        vim.env.HOME
            .. "/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-0.53.0.jar"
    ),
}

-- Helper function for creating keymaps
local function nnoremap(rhs, lhs, bufopts, desc)
    bufopts.desc = desc
    vim.keymap.set("n", rhs, lhs, bufopts)
end
-- 运行/调试单元测试所需
-- vim.list_extend(bundles, vim.split(vim.fn.glob(vim.env.HOME .. "/dev/java/vscode-java-test/server/*.jar", 1), "\n"))
vim.list_extend(
    bundles,
    vim.split(
        vim.fn.glob(vim.env.HOME .. "/.local/share/nvim/mason/packages/java-test/extension/server/*.jar", 1),
        "\n"
    )
)

-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
-- 查看vim.lsp.start_client的帮助文档，了解支持的config选项
local config = {
    -- 启动语言服务器的命令
    -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
    cmd = {
        -- 使用jenv执行java，这样可以切换不同的java版本
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-javaagent:" .. vim.env.HOME .. "/.local/share/nvim/mason/share/jdtls/lombok.jar", -- 启动lombok支持
        "-Xmx4g", -- 设置最大堆内存为4G
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",

        -- Eclipse jdtls location
        "-jar",
        -- self  compile path /dev/java/eclipse.jdt.ls/org.eclipse.jdt.ls.product/target/repository/plugins/org.eclipse.equinox.launcher_1.6.900.v20240613-2009.jar

        vim.env.HOME
            .. "/.local/share/nvim/mason/share/jdtls/plugins/org.eclipse.equinox.launcher_1.6.900.v20240613-2009.jar",
        -- TODO Update this to point to the correct jdtls subdirectory for your OS (config_linux, config_mac, config_win, etc)
        "-configuration",
        vim.env.HOME .. "/.local/share/nvim/mason/packages/jdtls/config_mac_arm",
        "-data",
        workspace_dir,
    },

    -- 若未提供，将使用默认值，每个独特的root_dir都会启动一个专用的LSP服务器和客户端
    root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "pom.xml", "build.gradle" }),

    -- 此处可以配置Eclipse jdt.ls的特定配置
    -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
    settings = {
        java = {
            -- TODO Replace this with the absolute path to your main java version (JDK 17 or higher)
            home = "/opt/homebrew/Cellar/openjdk@21/21.0.5/libexec/openjdk.jdk/Contents/Home",
            eclipse = {
                -- 启用下载源码
                downloadSources = true,
            },
            configuration = {
                updateBuildConfiguration = "interactive",
                -- TODO  根据需要添加支持的java版本，删除未安装的版本
                -- 运行时名称参数需要匹配特定的Java执行环境，详见nlsp-settings文档
                -- The runtime name parameters need to match specific Java execution environments.  See https://github.com/tamago324/nlsp-settings.nvim/blob/2a52e793d4f293c0e1d61ee5794e3ff62bfbbb5d/schemas/_generated/jdtls.json#L317-L334
                runtimes = {
                    {
                        name = "JavaSE-11",
                        path = "/opt/homebrew/Cellar/openjdk@11/11.0.25/libexec/openjdk.jdk/Contents/Home",
                        version = "11",
                    },
                    {
                        name = "JavaSE-17",
                        path = "/opt/homebrew/Cellar/openjdk@17/17.0.13/libexec/openjdk.jdk/Contents/Home",
                        version = "17",
                    },
                    -- {
                    --     name = "JavaSE-21",
                    --     path = "/opt/homebrew/Cellar/openjdk@21/21.0.5/libexec/openjdk.jdk/Contents/Home",
                    --     version = "21",
                    -- },
                    -- {
                    --     name = "JavaSE-23",
                    --     path = "/opt/homebrew/Cellar/openjdk/23.0.1/libexec/openjdk.jdk/Contents/Home",
                    --     version = "23",
                    -- },
                },
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
                -- 可以参考特定的文件/URL进行格式化
                -- Formatting works by default, but you can refer to a specific file/URL if you choose
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
        -- References the bundles defined above to support Debugging and Unit Testing
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
        nnoremap("<leader>oi", jdtls.organize_imports, bufopts, "优化导入")
        nnoremap("<space>ev", jdtls.extract_variable, bufopts, "提取变量")
        nnoremap("<space>ec", jdtls.extract_constant, bufopts, "提取常量")
        vim.keymap.set(
            "v",
            "<space>em",
            [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
            { noremap = true, silent = true, buffer = bufnr, desc = "提取方法" }
        )
        nnoremap("<leader>vc", jdtls.test_class, bufopts, "Test class (DAP)")
        nnoremap("<leader>vm", jdtls.test_nearest_method, bufopts, "Test method (DAP)")
    end,
}

-- 启用一个新的客户端和服务器，或基于root_dir附加到已有的客户端和服务器
jdtls.start_or_attach(config)
