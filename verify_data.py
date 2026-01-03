#!/usr/bin/env python3
import sqlite3
from datetime import datetime

conn = sqlite3.connect("awareness_v6.sqlite")
cursor = conn.cursor()

print("📊 数据库内容验证\n")

# 统计各表记录数
tables = ['objectives', 'key_results', 'tasks', 'focus_sessions', 'thoughts']
for table in tables:
    cursor.execute(f"SELECT COUNT(*) FROM {table}")
    count = cursor.fetchone()[0]
    print(f"  {table}: {count} 条记录")

print("\n⏰ 今日专注会话时间分布：\n")
cursor.execute("""
    SELECT
        datetime(start_time, 'unixepoch') as time,
        focus_quality,
        duration_seconds / 60 as duration_mins,
        (duration_seconds / 60.0) * (focus_quality / 5.0) as effective_mins
    FROM focus_sessions
    ORDER BY start_time
""")

total_mins = 0
total_effective = 0
for row in cursor.fetchall():
    time, quality, duration, effective = row
    total_mins += duration
    total_effective += effective
    print(f"  {time} | ⭐{quality}/5 | {duration:.0f}分钟 → 有效 {effective:.1f}分钟")

print(f"\n  总计: {total_mins:.0f}分钟 → 有效时间 {total_effective:.1f}分钟")
print(f"  平均效率: {(total_effective/total_mins*100):.1f}%")

print("\n🎯 目标概览：\n")
cursor.execute("""
    SELECT title, calculated_progress
    FROM objectives
    WHERE status = 'active'
    ORDER BY created_at
""")

for row in cursor.fetchall():
    title, progress = row
    print(f"  • {title}: {progress:.0f}%")

conn.close()
