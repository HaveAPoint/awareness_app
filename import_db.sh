#!/bin/bash
# 一键导入数据库脚本

echo "🔍 正在查找应用数据库..."

# 查找数据库位置（应用至少运行过一次）
DB_PATH=$(find ~/.local/share -name "awareness_v6.sqlite" 2>/dev/null | head -1)

if [ -z "$DB_PATH" ]; then
    echo ""
    echo "❌ 未找到数据库文件！"
    echo ""
    echo "请先执行以下操作："
    echo "1. cd /home/wsl1/awareness_app/frontend"
    echo "2. flutter run -d linux"
    echo "3. 等待应用启动后关闭"
    echo "4. 再次运行本脚本"
    echo ""
    exit 1
fi

echo "📍 找到数据库: $DB_PATH"
echo ""

# 备份原数据库
BACKUP_PATH="$DB_PATH.backup_$(date +%Y%m%d_%H%M%S)"
cp "$DB_PATH" "$BACKUP_PATH"
echo "💾 已备份原数据库到: $BACKUP_PATH"

# 替换为模拟数据
cp /home/wsl1/awareness_app/awareness_v6.sqlite "$DB_PATH"
echo "✅ 数据库已替换！"
echo ""
echo "🎉 导入完成！"
echo ""
echo "包含数据："
echo "  - 3个活跃目标"
echo "  - 10个今日专注会话（2026-01-01）"
echo "  - 183分钟有效时间（质量加权）"
echo ""
echo "🚀 现在运行应用即可查看效果："
echo "   cd /home/wsl1/awareness_app/frontend && flutter run -d linux"
