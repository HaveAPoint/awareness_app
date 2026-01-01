#!/bin/bash

# Awareness App - Chrome (Web) 程序构建脚本
# 在项目根目录执行（与 build_linux.sh 风格一致）

set -euo pipefail

echo "================================================"
echo "   Awareness App - Chrome (Web) 构建"
echo "================================================"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

echo ""
echo "步骤 1: 检查 Flutter 环境..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter 未安装，请先安装 Flutter SDK"
fi
print_success "Flutter 已安装: $(flutter --version | head -n 1)"

echo ""
echo "步骤 2: 检查 Flutter Web 支持..."
if ! flutter config | grep -q "enable-web: true"; then
    print_warning "Web 支持未启用，正在启用..."
    flutter config --enable-web
fi
print_success "Flutter Web 支持已启用"

echo ""
echo "步骤 3: 检查 Chrome/Chromium 可用性..."
CHROME_CMD=""
for c in google-chrome-stable google-chrome chromium-browser chromium; do
    if command -v "$c" &> /dev/null; then
        CHROME_CMD=$(command -v "$c")
        break
    fi
done

if [ -z "$CHROME_CMD" ]; then
    print_warning "未找到 Chrome/Chromium 可执行文件。脚本会继续构建，但自动在浏览器中打开会被跳过。"
    print_warning "如果想自动打开，请安装 Chrome 或设置环境变量 CHROME_EXECUTABLE=/path/to/chrome"
else
    print_success "检测到浏览器: $CHROME_CMD"
fi

echo ""
echo "步骤 4: 进入前端目录并获取依赖..."
cd frontend || print_error "frontend 目录不存在"
print_success "已进入 frontend 目录"

flutter pub get
print_success "依赖获取完成"

echo ""
echo "步骤 5: 清理旧构建..."
flutter clean
print_success "清理完成"

echo ""
echo "步骤 6: 构建 Web (release)..."
flutter build web --release
print_success "Web 构建完成"

BUNDLE_PATH="build/web"
echo ""
echo "构建产物路径: $(pwd)/$BUNDLE_PATH"
if [ -d "$BUNDLE_PATH" ]; then
    du -sh "$BUNDLE_PATH" | awk '{print "  " $1 "\t" $2}'
else
    print_warning "找不到构建目录 $BUNDLE_PATH"
fi

echo ""
echo "================================================"
print_success "构建成功！"
echo "================================================"
echo "运行/测试选项："
echo "1. 直接打开本地静态文件（某些功能可能受限制）。"
echo "   打开: frontend/$BUNDLE_PATH/index.html"
echo "2. 使用内置 HTTP 服务（推荐），并在 Chrome 中打开。"
echo "   启动服务: python3 -m http.server 8000 （在 frontend/$BUNDLE_PATH 目录）"
echo "   或者运行本脚本后自动打开浏览器（如果检测到 Chrome）。"
echo "================================================"
echo ""

echo "正在尝试以本地服务器方式启动并在浏览器中打开（如果可用）..."

if command -v python3 &> /dev/null; then
    serve_cmd="python3 -m http.server 8000"
    (cd "$BUNDLE_PATH" && nohup $serve_cmd > /dev/null 2>&1 &) || true
    print_success "已在 build 目录内以 http://127.0.0.1:8000 提供静态文件（后台运行）"
    sleep 1
    URL="http://127.0.0.1:8000"
    # 优先使用环境变量 CHROME_EXECUTABLE
    if [ -n "${CHROME_EXECUTABLE-}" ]; then
        BROWSER_CMD="$CHROME_EXECUTABLE"
    else
        BROWSER_CMD="$CHROME_CMD"
    fi

    if [ -n "$BROWSER_CMD" ] && command -v "$BROWSER_CMD" &> /dev/null; then
        "$BROWSER_CMD" "$URL" &> /dev/null &
        print_success "已在 Chrome 中打开: $URL"
    else
        print_warning "未能自动在 Chrome 中打开，请手动访问: $URL"
    fi
else
    print_warning "未检测到 python3，无法自动启动 http 服务器。请手动在 $BUNDLE_PATH 启动服务器并打开 index.html"
fi

echo ""
echo "完成。"
