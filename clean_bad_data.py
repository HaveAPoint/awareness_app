#!/usr/bin/env python3
"""清理错误数据并重新插入"""

import sqlite3
import glob
import os

def find_database():
    """查找数据库"""
    possible_paths = [
        os.path.expanduser("~/.local/share/*/awareness_v6.sqlite"),
    ]

    for pattern in possible_paths:
        matches = glob.glob(pattern)
        if matches:
            return matches[0]
    return None

def clean_and_reinsert(db_path):
    """清理错误数据"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print(f"📂 数据库: {db_path}\n")

    # 删除可能有错误的今日数据
    print("🧹 清理可能的错误数据...")

    # 查找并删除 created_at 为文本格式的记录
    cursor.execute("DELETE FROM objectives WHERE typeof(created_at) = 'text'")
    deleted_obj = cursor.rowcount

    cursor.execute("DELETE FROM key_results WHERE typeof(created_at) = 'text'")
    deleted_kr = cursor.rowcount

    cursor.execute("DELETE FROM tasks WHERE typeof(created_at) = 'text'")
    deleted_tasks = cursor.rowcount

    cursor.execute("DELETE FROM focus_sessions WHERE typeof(created_at) = 'text'")
    deleted_sessions = cursor.rowcount

    cursor.execute("DELETE FROM thoughts WHERE typeof(created_at) = 'text'")
    deleted_thoughts = cursor.rowcount

    conn.commit()

    print(f"  已删除: {deleted_obj} 个目标")
    print(f"  已删除: {deleted_kr} 个关键结果")
    print(f"  已删除: {deleted_tasks} 个任务")
    print(f"  已删除: {deleted_sessions} 个会话")
    print(f"  已删除: {deleted_thoughts} 个杂念")

    conn.close()

    print("\n✅ 清理完成！")
    print("\n💡 现在运行: python3 insert_to_existing_db.py")

if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        db_path = sys.argv[1]
    else:
        db_path = find_database()

    if db_path and os.path.exists(db_path):
        clean_and_reinsert(db_path)
    else:
        print("❌ 未找到数据库文件")
        print("手动指定: python3 clean_bad_data.py /path/to/awareness_v6.sqlite")
