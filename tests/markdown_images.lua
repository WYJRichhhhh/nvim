-- Integration: nvim --headless -n -i NONE -u ./init.lua -l tests/markdown_images.lua
local ok, err = xpcall(function()
    assert(vim.fn.executable("mmdc") == 1, "Install Mermaid CLI; see docs/markdown.md")
    assert(vim.fn.executable("magick") == 1, "Install ImageMagick")
    assert(Snacks.image.config.enabled)
    vim.cmd.edit("docs/markdown.md")
    local buf = vim.api.nvim_get_current_buf()
    assert(vim.fn.exists(":MermaidPreview") == 2)
    assert(vim.fn.maparg(" mp", "n", false, true).buffer == 1)
    local opts = require("core.markdown_images").options()
    local args = opts.convert.mermaid()
    assert(args[8] == (vim.o.background == "light" and "neutral" or "dark"))
    local images
    Snacks.image.doc.find(buf, function(found)
        images = found
    end)
    assert(vim.wait(3000, function()
        return images ~= nil
    end))
    assert(#images == 2, "Expected flowchart and sequence diagram, got " .. #images)
    -- No terminal graphics are sent by this headless conversion test.
    Snacks.image.terminal.size = function()
        return { scale = 1 }
    end
    for _, image in ipairs(images) do
        assert(image.type == "chart" and image.src:match("%.mmd$"))
        local converted
        local converter = Snacks.image.convert.convert({
            src = image.src,
            on_done = function(value)
                converted = value
            end,
        })
        converter:run()
        assert(
            vim.wait(30000, function()
                return converted ~= nil
            end),
            "conversion timed out"
        )
        assert(not converted._err, converted._err)
        assert(converted.meta.info and converted.meta.info.format == "png")
        assert(converted.meta.info.size.width > 10 and converted.meta.info.size.height > 10)
    end
    assert(vim.tbl_contains(require("render-markdown.state").config.code.disable, "mermaid"))
    print(
        "MARKDOWN_MERMAID_OK Markdown parser / flowchart + sequence / real Chromium PNG / image metadata / buffer-local preview"
    )
end, debug.traceback)
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd.cquit(1)
end
vim.cmd("qa!")
