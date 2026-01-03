#!/bin/bash

# 1. 找到数据库位置
DB_DIR="$HOME/.local/share/awareness_app/frontend"
DB_FILE="$DB_DIR/awareness_v6.sqlite"

# 2. 创建目录（如果不存在）
mkdir -p "$DB_DIR"

# 3. 复制模拟数据库
cp /home/wsl1/awareness_app/awareness_v6.sqlite "$DB_FILE"

echo "✅ 数据库已复制到: $DB_FILE"
echo "💡 现在运行 Flutter 应用即可查看效果"
