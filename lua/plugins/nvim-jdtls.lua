-- Java LSP（jdtls）
return {
    -- https://github.com/mfussenegger/nvim-jdtls
    "mfussenegger/nvim-jdtls",
    ft = "java", -- 仅在 .java 文件上启用
    dependencies = {
        -- https://github.com/mfussenegger/nvim-dap
        "mfussenegger/nvim-dap",
    },
}
