local M = {}

-- Prefer an explicit browser, then an installed browser, then an existing cache.
-- Paths are detected per machine; no browser binary or machine path is committed.
local function browser()
    local paths = { vim.env.PUPPETEER_EXECUTABLE_PATH }
    for _, file in ipairs({
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Chromium.app/Contents/MacOS/Chromium",
    }) do
        paths[#paths + 1] = file
    end
    for _, name in ipairs({ "chromium", "chromium-browser", "google-chrome" }) do
        paths[#paths + 1] = vim.fn.exepath(name)
    end
    for _, pattern in ipairs({
        "~/Library/Caches/ms-playwright/chromium-*/chrome-mac-*/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing",
        "~/.cache/ms-playwright/chromium-*/chrome-linux*/chrome",
        "~/.cache/puppeteer/chrome/*/chrome-*/chrome",
        "~/.cache/puppeteer/chrome/*/chrome-mac-*/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing",
    }) do
        local found = vim.fn.glob(vim.fn.expand("~") .. pattern:sub(2), false, true)
        table.sort(found, function(a, b)
            return vim.fn.getftime(a) > vim.fn.getftime(b)
        end)
        vim.list_extend(paths, found)
    end
    for _, file in ipairs(paths) do
        if file ~= "" and vim.fn.executable(file) == 1 then
            return file
        end
    end
end

function M.options()
    local delimiter = vim.fn.has("win32") == 1 and ";" or ":"
    local bin = vim.fn.stdpath("data") .. "/mermaid/node_modules/.bin"
    if
        vim.fn.isdirectory(bin) == 1
        and not vim.tbl_contains(vim.split(vim.env.PATH or "", delimiter, { plain = true }), bin)
    then
        vim.env.PATH = bin .. delimiter .. (vim.env.PATH or "")
    end
    local executable = browser()
    local puppeteer
    if executable then
        local cache = vim.fn.stdpath("cache") .. "/mermaid"
        vim.fn.mkdir(cache, "p")
        puppeteer = cache .. "/puppeteer.json"
        vim.fn.writefile({ vim.json.encode({ executablePath = executable }) }, puppeteer)
    end
    return {
        enabled = true,
        math = { enabled = false },
        doc = {
            inline = true,
            float = true,
            conceal = function(_, kind)
                return kind == "chart"
            end,
        },
        convert = {
            mermaid = function()
                local args = {
                    "-i",
                    "{src}",
                    "-o",
                    "{file}",
                    "-b",
                    "transparent",
                    "-t",
                    vim.o.background == "light" and "neutral" or "dark",
                    "-s",
                    "{scale}",
                }
                if puppeteer then
                    vim.list_extend(args, { "-p", puppeteer })
                end
                return args
            end,
        },
    }
end

function M.preview()
    if vim.fn.executable("mmdc") ~= 1 or vim.fn.executable("magick") ~= 1 then
        vim.notify("Mermaid 需要 mmdc 和 ImageMagick；安装说明见 docs/markdown.md。", vim.log.levels.WARN)
        return
    end
    require("snacks").image.hover()
end

return M
