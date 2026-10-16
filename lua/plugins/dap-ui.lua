-- UI 配置独立于语言，Java 和 Python 都能正常打开调试界面。
return {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
        local dap, ui = require("dap"), require("dapui")
        ui.setup()
        dap.listeners.after.event_initialized["dapui"] = ui.open
        dap.listeners.before.event_terminated["dapui"] = ui.close
        dap.listeners.before.event_exited["dapui"] = ui.close
    end,
}
