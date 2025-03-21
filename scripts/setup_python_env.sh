#!/bin/bash
# Python开发环境设置脚本

echo "开始设置Python开发环境..."

# 确保目录存在
mkdir -p ~/.config/nvim/snippets/python

# 检查并安装必要的Python工具
echo "正在检查Python工具..."

# 检查pip是否存在
if ! command -v pip3 &> /dev/null; then
    echo "未找到pip3，请先安装Python3"
    exit 1
fi

# 安装必要的Python工具
echo "安装Python开发工具..."
pip3 install --user --upgrade \
    pylint \
    black \
    isort \
    flake8 \
    ruff \
    mypy \
    pynvim \
    autoflake \
    pytest \
    debugpy

# 检查是否需要安装Node.js和npm (一些LSP服务依赖)
if ! command -v npm &> /dev/null; then
    echo "未找到npm，建议安装Node.js和npm"
    echo "可以访问 https://nodejs.org/ 下载"
fi

# 确保Mason包管理器可以安装语言服务器
echo "确保所有Python插件和LSP服务器可用..."

# 告诉用户需要在nvim中运行的命令
echo ""
echo "=========================================================="
echo "设置完成！请在Neovim中运行以下命令来安装插件:"
echo ":Lazy"
echo ""
echo "然后安装所有Python相关的语言服务器:"
echo ":MasonInstall pyright ruff-lsp black isort debugpy"
echo "=========================================================="
echo ""
echo "重启Neovim使所有配置生效!" 