#!/bin/bash
# 导入模拟数据库的步骤

echo "📋 导入数据库步骤："
echo ""
echo "方法1: 手动替换（推荐）"
echo "============================"
echo "1️⃣  先运行一次应用（让它创建数据库文件）："
echo "   cd /home/wsl1/awareness_app/frontend"
echo "   flutter run -d linux"
echo ""
echo "2️⃣  关闭应用后，找到数据库文件："
echo "   数据库位置通常在: ~/.local/share/awareness_app/frontend/"
echo "   或运行: find ~ -name 'awareness_v6.sqlite' 2>/dev/null"
echo ""
echo "3️⃣  替换数据库："
echo "   cp /home/wsl1/awareness_app/awareness_v6.sqlite \\"
echo "      ~/.local/share/com.example.awareness_app/awareness_v6.sqlite"
echo ""
echo "4️⃣  重新运行应用查看效果"
echo ""
echo "================================"
echo "方法2: 自动脚本（需要先运行一次应用）"
echo "================================"
echo ""
echo "运行以下命令查找并替换："
echo ""

cat << 'SCRIPT'
# 查找数据库位置
DB_PATH=$(find ~/.local/share -name "awareness_v6.sqlite" 2>/dev/null | head -1)

if [ -z "$DB_PATH" ]; then
    echo "❌ 未找到数据库文件，请先运行一次应用"
    exit 1
fi

echo "📍 找到数据库: $DB_PATH"

# 备份原数据库
cp "$DB_PATH" "$DB_PATH.backup"
echo "💾 已备份原数据库"

# 替换为模拟数据
cp /home/wsl1/awareness_app/awareness_v6.sqlite "$DB_PATH"
echo "✅ 数据库已替换！"
echo "🚀 现在重新运行应用即可查看效果"
SCRIPT
