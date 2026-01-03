#!/usr/bin/env python3
"""
直接向现有数据库插入模拟数据
不会删除或替换现有数据
"""

import sqlite3
import uuid
from datetime import datetime, timedelta
import os
import glob

# 今天的日期：2026-01-01
TODAY = datetime(2026, 1, 1)


def find_database():
    """查找应用数据库文件"""
    # 可能的位置
    possible_paths = [
        os.path.expanduser("~/.local/share/*/awareness_v6.sqlite"),
        os.path.expanduser("~/Documents/awareness_v6.sqlite"),
        "./frontend/build/linux/x64/release/bundle/data/flutter_assets/awareness_v6.sqlite",
    ]

    for pattern in possible_paths:
        matches = glob.glob(pattern)
        if matches:
            return matches[0]

    return None


def insert_mock_data(db_path):
    """向现有数据库插入模拟数据"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print(f"📂 数据库: {db_path}\n")

    # 检查是否已有数据
    cursor.execute("SELECT COUNT(*) FROM objectives")
    existing_objectives = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM focus_sessions WHERE date(start_time, 'unixepoch') = date('2026-01-01')")
    existing_sessions_today = cursor.fetchone()[0]

    print(f"📊 现有数据:")
    print(f"  - 目标: {existing_objectives} 个")
    print(f"  - 今日会话: {existing_sessions_today} 个\n")

    try:
        # ========== 1. 创建目标 ==========
        objectives_data = [
            {
                'id': str(uuid.uuid4()),
                'title': '完成《深度工作》读书笔记',
                'description': '阅读并总结《深度工作》一书的核心要点',
                'period': '2026-Q1',
                'deadline': int((TODAY + timedelta(days=90)).timestamp()),
            },
            {
                'id': str(uuid.uuid4()),
                'title': '开发 Awareness App MVP',
                'description': '完成自我觉知应用的最小可行产品',
                'period': '2026-01',
                'deadline': int((TODAY + timedelta(days=30)).timestamp()),
            },
            {
                'id': str(uuid.uuid4()),
                'title': '每日冥想练习',
                'description': '建立每日冥想的习惯',
                'period': '2026-01',
                'deadline': int((TODAY + timedelta(days=30)).timestamp()),
            },
        ]

        for obj in objectives_data:
            cursor.execute("""
                INSERT INTO objectives
                (id, title, description, period, deadline, status, calculated_progress, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, 'active', 0.0, ?, ?)
            """, (
                obj['id'], obj['title'], obj['description'], obj['period'],
                obj['deadline'], int(TODAY.timestamp()), int(TODAY.timestamp())
            ))

        print(f"✅ 插入了 {len(objectives_data)} 个目标")

        # ========== 2. 创建关键结果 ==========
        key_results_data = [
            {'objective_id': objectives_data[0]['id'], 'title': '阅读完整本书', 'target_val': 100.0, 'current_val': 30.0},
            {'objective_id': objectives_data[0]['id'], 'title': '撰写笔记章节', 'target_val': 10.0, 'current_val': 2.0},
            {'objective_id': objectives_data[1]['id'], 'title': '完成核心功能', 'target_val': 5.0, 'current_val': 2.0},
            {'objective_id': objectives_data[1]['id'], 'title': '编写单元测试', 'target_val': 100.0, 'current_val': 45.0},
            {'objective_id': objectives_data[2]['id'], 'title': '完成冥想天数', 'target_val': 30.0, 'current_val': 18.0},
        ]

        for i, kr in enumerate(key_results_data):
            kr['id'] = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO key_results
                (id, objective_id, title, type, start_val, target_val, current_val, created_at, updated_at)
                VALUES (?, ?, ?, 'number', 0.0, ?, ?, ?, ?)
            """, (kr['id'], kr['objective_id'], kr['title'], kr['target_val'], kr['current_val'],
                  int(TODAY.timestamp()), int(TODAY.timestamp())))
            key_results_data[i] = kr

        print(f"✅ 插入了 {len(key_results_data)} 个关键结果")

        # ========== 3. 创建任务 ==========
        tasks_data = [
            {'kr_id': key_results_data[0]['id'], 'title': '阅读第1-3章', 'status': 'done'},
            {'kr_id': key_results_data[0]['id'], 'title': '阅读第4-6章', 'status': 'in_progress'},
            {'kr_id': key_results_data[1]['id'], 'title': '撰写第一章笔记', 'status': 'done'},
            {'kr_id': key_results_data[2]['id'], 'title': '实现番茄钟功能', 'status': 'done'},
            {'kr_id': key_results_data[2]['id'], 'title': '实现可视化组件', 'status': 'in_progress'},
            {'kr_id': key_results_data[4]['id'], 'title': '早晨冥想', 'status': 'done'},
        ]

        for i, task in enumerate(tasks_data):
            task['id'] = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO tasks
                (id, kr_id, title, status, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (task['id'], task['kr_id'], task['title'], task['status'],
                  int(TODAY.timestamp()), int(TODAY.timestamp())))
            tasks_data[i] = task

        print(f"✅ 插入了 {len(tasks_data)} 个任务")

        # ========== 4. 创建今天的专注会话 ==========
        sessions_config = [
            {'hour': 8, 'minute': 0, 'task_idx': 0, 'quality': 4, 'duration': 25},
            {'hour': 8, 'minute': 30, 'task_idx': 0, 'quality': 5, 'duration': 25},
            {'hour': 10, 'minute': 0, 'task_idx': 1, 'quality': 3, 'duration': 25},
            {'hour': 10, 'minute': 35, 'task_idx': 1, 'quality': 2, 'duration': 25},
            {'hour': 14, 'minute': 0, 'task_idx': 3, 'quality': 5, 'duration': 25},
            {'hour': 14, 'minute': 30, 'task_idx': 3, 'quality': 4, 'duration': 25},
            {'hour': 16, 'minute': 0, 'task_idx': 4, 'quality': 3, 'duration': 25},
            {'hour': 19, 'minute': 0, 'task_idx': 5, 'quality': 4, 'duration': 25},
            {'hour': 19, 'minute': 35, 'task_idx': 5, 'quality': 5, 'duration': 25},
            {'hour': 21, 'minute': 0, 'task_idx': 1, 'quality': 2, 'duration': 20},
        ]

        sessions_data = []
        for config in sessions_config:
            start_time = TODAY.replace(hour=config['hour'], minute=config['minute'])
            end_time = start_time + timedelta(minutes=config['duration'])

            session_id = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO focus_sessions
                (id, task_id, start_time, end_time, duration_seconds, type, status, focus_quality, review_note, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, 'work', 'completed', ?, ?, ?, ?)
            """, (
                session_id,
                tasks_data[config['task_idx']]['id'],
                int(start_time.timestamp()),
                int(end_time.timestamp()),
                config['duration'] * 60,
                config['quality'],
                f"专注质量: {config['quality']}/5",
                int(TODAY.timestamp()),
                int(TODAY.timestamp())
            ))
            sessions_data.append({'id': session_id, 'quality': config['quality'], 'duration': config['duration']})

        print(f"✅ 插入了 {len(sessions_data)} 个专注会话")

        # ========== 5. 创建杂念 ==========
        thoughts_data = [
            {'session_id': sessions_data[3]['id'], 'content': '想起下午要开会', 'type': 'distraction'},
            {'session_id': sessions_data[3]['id'], 'content': '手机震动，收到消息', 'type': 'distraction'},
            {'session_id': sessions_data[9]['id'], 'content': '有点累了，想休息', 'type': 'distraction'},
            {'session_id': None, 'content': '记得买牛奶', 'type': 'todo'},
            {'session_id': sessions_data[4]['id'], 'content': '这个算法可以优化', 'type': 'idea'},
        ]

        for thought in thoughts_data:
            cursor.execute("""
                INSERT INTO thoughts
                (id, session_id, content, type, is_resolved, created_at)
                VALUES (?, ?, ?, ?, 0, ?)
            """, (str(uuid.uuid4()), thought['session_id'], thought['content'], thought['type'], int(TODAY.timestamp())))

        print(f"✅ 插入了 {len(thoughts_data)} 个杂念记录")

        # 计算有效时间
        total_effective = sum([
            (s['duration'] * (s['quality'] / 5.0))
            for s in sessions_data
        ])

        conn.commit()

        print("\n🎉 数据插入成功！")
        print(f"\n⏰ 今日有效时间: {total_effective:.1f} 分钟")
        print("\n💡 现在运行应用，点击右下角'眼睛'按钮查看 Mirror 可视化效果")

    except Exception as e:
        print(f"\n❌ 错误: {e}")
        conn.rollback()
    finally:
        conn.close()


def main():
    print(f"📅 模拟日期: {TODAY.strftime('%Y-%m-%d')}\n")

    # 先尝试查找现有数据库
    db_path = find_database()

    if db_path and os.path.exists(db_path):
        print(f"✅ 找到数据库: {db_path}\n")
        insert_mock_data(db_path)
    else:
        print("❌ 未找到数据库文件！\n")
        print("请先运行一次应用:")
        print("  cd /home/wsl1/awareness_app/frontend")
        print("  flutter run -d linux\n")
        print("或手动指定数据库路径:")
        print("  python3 insert_to_existing_db.py /path/to/awareness_v6.sqlite")


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        # 手动指定数据库路径
        db_path = sys.argv[1]
        if os.path.exists(db_path):
            insert_mock_data(db_path)
        else:
            print(f"❌ 文件不存在: {db_path}")
    else:
        main()
