#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# PostToolUse 钩子：拦截写死的机器特定绝对路径。
#
# 为什么要这个钩子：这套 nvim 配置托管在 GitHub，核心诉求是「在任意机器上
# clone 下来就能用」。一旦某个 .lua 里写死了 /Users/rich/... 或 /opt/homebrew/...
# 这类只在本机成立的路径，迁到别的机器（不同用户名 / OS / CPU 架构 / 安装位置）
# 就会大面积报错。这类错误机器可以机械检出，所以交给钩子兜底，而不是靠人记。
#
# 工作方式：每次 Edit/Write/MultiEdit 落到 .lua 文件后，扫描「这次新写入的内容」，
# 命中写死路径就把中文整改建议回灌给 Claude（写 stderr + exit 2），让它当场改正。
#
# 放行规则（这些地方写绝对路径是合理的，不报）：
#   - lua/local.lua          —— 机器特定覆盖，本就 .gitignore、不入库
#   - *.example              —— 模板，本来就让人按本机填路径
#   - 纯注释行 / 行内注释部分 —— 注释里举反例、说明背景不算违规
#
# 退出码约定：exit 0 放行；exit 2 表示发现问题，stderr 文本会回灌给 Claude。

import json
import os
import re
import sys


# (正则, 整改提示)。提示直接给出本项目约定的正确替代写法（见 CLAUDE.md）。
PATTERNS = [
    (re.compile(r"/Users/"),
     "macOS 用户家目录写死了。家目录用 vim.env.HOME / os.getenv(\"HOME\")，"
     "nvim 数据目录用 vim.fn.stdpath(\"data\")、配置目录用 stdpath(\"config\")。"),
    (re.compile(r"/home/[A-Za-z0-9._-]+"),
     "Linux 用户家目录写死了。换用 vim.env.HOME / stdpath()，别钉死用户名。"),
    (re.compile(r"/root/"),
     "/root 是特定环境的家目录，换用 vim.env.HOME / stdpath()。"),
    (re.compile(r"/opt/homebrew"),
     "/opt/homebrew 只在 Apple Silicon 的 brew 上成立（Intel 是 /usr/local，"
     "Linux 又不同）。mason 装的工具一律走 vim.fn.stdpath(\"data\") .. \"/mason\"；"
     "平台差异用 jit.os / jit.arch 分支。"),
    (re.compile(r"/usr/local/Cellar"),
     "/usr/local/Cellar 是 Intel mac 的 brew 路径，不可移植。理由同上，走 stdpath/分支探测。"),
    (re.compile(r"~/\.local/share/nvim"),
     "~/.local/share/nvim 是 nvim 数据目录的硬编码形式，换成 vim.fn.stdpath(\"data\")。"),
    (re.compile(r"~/\.config/nvim"),
     "~/.config/nvim 是 nvim 配置目录的硬编码形式，换成 vim.fn.stdpath(\"config\")。"),
    (re.compile(r"[A-Za-z]:\\\\"),
     "Windows 盘符路径（如 C:\\\\）写死了，用 stdpath() / vim.env 让它自适应。"),
]


def strip_lua_comment(line):
    """去掉 Lua 行内/整行注释，只返回代码部分。

    注释里出现绝对路径是允许的（举反例、写背景说明），所以扫描前先把注释剥掉。
    用一个极简状态机识别字符串，避免把字符串里的 -- 误当成注释起点。
    不处理 [[ ]] 长字符串/长注释 —— 配置里几乎不用，简单优先。
    """
    in_str = None  # 当前所处的字符串引号（' 或 "），None 表示在代码区
    i = 0
    n = len(line)
    while i < n:
        c = line[i]
        if in_str:
            if c == "\\":  # 跳过转义的下一个字符
                i += 2
                continue
            if c == in_str:
                in_str = None
        else:
            if c in ("'", '"'):
                in_str = c
            elif c == "-" and i + 1 < n and line[i + 1] == "-":
                return line[:i]  # 命中代码区里的 --，其后全是注释
        i += 1
    return line


def collect_new_text(tool_name, tool_input):
    """取出本次操作「新写入」的文本（不同工具字段不同）。"""
    if tool_name == "Write":
        return tool_input.get("content", "") or ""
    if tool_name == "Edit":
        return tool_input.get("new_string", "") or ""
    if tool_name == "MultiEdit":
        return "\n".join(
            e.get("new_string", "") or "" for e in tool_input.get("edits", [])
        )
    return ""


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        # 拿不到/解析不了输入，不阻断正常流程
        sys.exit(0)

    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {}) or {}
    file_path = tool_input.get("file_path", "") or ""

    # 只管 Lua 文件
    if not file_path.endswith(".lua"):
        sys.exit(0)

    base = os.path.basename(file_path)
    # 放行：机器特定覆盖文件本就该写本机路径；模板同理
    if base == "local.lua" or base.endswith(".example"):
        sys.exit(0)

    text = collect_new_text(tool_name, tool_input)
    if not text:
        sys.exit(0)

    hits = []  # (行号, 命中片段, 提示)
    for lineno, raw in enumerate(text.splitlines(), start=1):
        code = strip_lua_comment(raw)
        if not code.strip():
            continue
        for pat, hint in PATTERNS:
            m = pat.search(code)
            if m:
                hits.append((lineno, m.group(0), hint))
                break  # 一行命中一次即可，避免刷屏

    if not hits:
        sys.exit(0)

    lines = [
        "⚠ 检测到写死的机器特定路径（破坏跨机器移植，见 CLAUDE.md「跨机器移植」）：",
        "（文件：%s）" % file_path,
        "",
    ]
    for lineno, frag, hint in hits:
        lines.append("  · 第 %d 行附近：%s" % (lineno, frag))
        lines.append("      → %s" % hint)
    lines.append("")
    lines.append(
        "请改为自动探测的写法再继续。确属无法探测的本机值（如 JDK 安装路径），"
        "收敛到 lua/local.lua 并同步更新 lua/local.lua.example 模板。"
    )

    sys.stderr.write("\n".join(lines) + "\n")
    sys.exit(2)  # PostToolUse: exit 2 会把上面的 stderr 回灌给 Claude


if __name__ == "__main__":
    main()
