#!/bin/bash

# Awareness App - Android APK 构建脚本
# 在项目根目录执行

set -e

echo "================================================"
echo "   Awareness App - Android APK 构建"
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

# 2. 进入前端目录
cd frontend || print_error "frontend 目录不存在"
print_success "已进入 frontend 目录"

# 3. 获取依赖
echo ""
echo "步骤 2: 获取依赖..."
flutter pub get
print_success "依赖获取完成"

# 4. 清理旧构建
echo ""
echo "步骤 3: 清理旧构建..."
flutter clean
print_success "清理完成"

# 5. 构建 APK（Release 模式）
echo ""
echo "步骤 4: 构建 APK (可能需要 3-5 分钟)..."
flutter build apk --release
print_success "APK 构建完成"

# 6. 显示产物信息
echo ""
echo "================================================"
print_success "构建成功！"
echo "================================================"
echo ""
echo "APK 路径:"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
echo "  $(pwd)/$APK_PATH"
echo ""
echo "APK 大小:"
if [ -f "$APK_PATH" ]; then
    ls -lh "$APK_PATH" | awk '{print "  " $5}'
    echo ""
    echo "MD5 校验:"
    md5sum "$APK_PATH" | awk '{print "  " $1}'
fi
echo ""
echo "================================================"
echo "安装方法："
echo "1. 将 APK 传到手机"
echo "2. 在手机上允许「安装未知来源应用」"
echo "3. 点击 APK 安装"
echo ""
print_warning "首次安装可能需要授予存储权限"
