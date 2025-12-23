#!/bin/bash

# Awareness App - Linux 程序构建脚本
# 在项目根目录执行

set -e

echo "================================================"
echo "   Awareness App - Linux 程序构建"
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

# 1. 检查环境
echo ""
echo "步骤 1: 检查 Flutter 环境..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter 未安装，请先安装 Flutter SDK"
fi
print_success "Flutter 已安装: $(flutter --version | head -n 1)"

# 2. 检查 Linux 桌面支持
echo ""
echo "步骤 2: 检查 Linux 桌面支持..."
if ! flutter config | grep -q "enable-linux-desktop: true"; then
    print_warning "Linux 桌面支持未启用，正在启用..."
    flutter config --enable-linux-desktop
fi
print_success "Linux 桌面支持已启用"

# 3. 检查必要的系统依赖
echo ""
echo "步骤 3: 检查系统依赖..."
MISSING_DEPS=()
for cmd in cmake ninja pkg-config; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_DEPS+=($cmd)
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    print_error "缺少系统依赖: ${MISSING_DEPS[*]}\n请运行: sudo apt-get install cmake ninja-build pkg-config libgtk-3-dev"
fi
print_success "系统依赖检查通过"

# 4. 进入前端目录
cd frontend || print_error "frontend 目录不存在"
print_success "已进入 frontend 目录"

# 5. 获取依赖
echo ""
echo "步骤 4: 获取依赖..."
flutter pub get
print_success "依赖获取完成"

# 6. 清理旧构建
echo ""
echo "步骤 5: 清理旧构建..."
flutter clean
print_success "清理完成"

# 7. 构建 Linux 程序（Release 模式）
echo ""
echo "步骤 6: 构建 Linux 程序 (可能需要 3-5 分钟)..."
flutter build linux --release
print_success "Linux 程序构建完成"

# 8. 显示产物信息
echo ""
echo "================================================"
print_success "构建成功！"
echo "================================================"
echo ""
echo "程序路径:"
BUNDLE_PATH="build/linux/x64/release/bundle"
echo "  $(pwd)/$BUNDLE_PATH"
echo ""
echo "可执行文件:"
EXEC_FILE="$BUNDLE_PATH/awareness_app"
if [ -f "$EXEC_FILE" ]; then
    ls -lh "$EXEC_FILE" | awk '{print "  " $9 " (" $5 ")"}'
else
    # 尝试查找实际的可执行文件
    EXEC_FILE=$(find "$BUNDLE_PATH" -maxdepth 1 -type f -executable | head -n 1)
    if [ -n "$EXEC_FILE" ]; then
        ls -lh "$EXEC_FILE" | awk '{print "  " $9 " (" $5 ")"}'
    fi
fi
echo ""
echo "Bundle 总大小:"
du -sh "$BUNDLE_PATH" | awk '{print "  " $1}'
echo ""
echo "================================================"
echo "运行方法："
echo "1. 直接运行："
echo "   cd frontend/$BUNDLE_PATH && ./awareness_app"
echo ""
echo "2. 创建桌面快捷方式："
echo "   可将 bundle 目录复制到 /opt/ 或 ~/.local/share/"
echo ""
print_warning "确保已安装 GTK3 运行时库"
echo "================================================"
echo ""

# 9. 自动启动应用
echo "正在启动应用..."
cd "$BUNDLE_PATH" || print_error "无法进入 bundle 目录"

if [ -f "./awareness_app" ]; then
    print_success "启动 Awareness App"
    ./awareness_app
else
    print_error "找不到可执行文件 awareness_app"
fi



