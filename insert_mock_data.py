#!/usr/bin/env python3
"""
插入模拟数据到 Awareness App 数据库
日期：2026-01-01
"""

import sqlite3
import uuid
from datetime import datetime, timedelta
import random

# 数据库文件路径（根据实际情况调整）
DB_PATH = "awareness_v6.sqlite"

# 今天的日期：2026-01-01
TODAY = datetime(2026, 1, 1)


def create_tables(conn):
    """创建所有必要的表"""
    cursor = conn.cursor()

    # Objectives 表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS objectives (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        period TEXT,
        deadline INTEGER NOT NULL,
        status TEXT DEFAULT 'active',
        calculated_progress REAL DEFAULT 0.0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_synced INTEGER DEFAULT 0
    )
    """)

    # KeyResults 表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS key_results (
        id TEXT PRIMARY KEY,
        objective_id TEXT NOT NULL,
        title TEXT NOT NULL,
        type TEXT DEFAULT 'number',
        start_val REAL DEFAULT 0.0,
        target_val REAL NOT NULL,
        current_val REAL NOT NULL,
        unit TEXT,
        weight REAL DEFAULT 1.0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (objective_id) REFERENCES objectives(id) ON DELETE CASCADE
    )
    """)

    # Tasks 表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        kr_id TEXT,
        title TEXT NOT NULL,
        est_pomodoros INTEGER DEFAULT 1,
        actual_pomodoros INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 2,
        status TEXT DEFAULT 'todo',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (kr_id) REFERENCES key_results(id) ON DELETE SET NULL
    )
    """)

    # FocusSessions 表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS focus_sessions (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration_seconds INTEGER DEFAULT 0,
        type TEXT DEFAULT 'work',
        status TEXT NOT NULL,
        focus_quality INTEGER,
        review_note TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks(id)
    )
    """)

    # Thoughts 表
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS thoughts (
        id TEXT PRIMARY KEY,
        session_id TEXT,
        content TEXT NOT NULL,
        type TEXT DEFAULT 'distraction',
        is_resolved INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES focus_sessions(id)
    )
    """)

    conn.commit()
    print("✅ 表结构创建完成")


def insert_mock_data(conn):
    """插入模拟数据"""
    cursor = conn.cursor()

    # ========== 1. 创建目标 (Objectives) ==========
    objectives_data = [
        {
            'id': str(uuid.uuid4()),
            'title': '完成《深度工作》读书笔记',
            'description': '阅读并总结《深度工作》一书的核心要点',
            'period': '2026-Q1',
            'deadline': int((TODAY + timedelta(days=90)).timestamp()),
            'status': 'active',
            'calculated_progress': 25.0,
        },
        {
            'id': str(uuid.uuid4()),
            'title': '开发 Awareness App MVP',
            'description': '完成自我觉知应用的最小可行产品',
            'period': '2026-01',
            'deadline': int((TODAY + timedelta(days=30)).timestamp()),
            'status': 'active',
            'calculated_progress': 40.0,
        },
        {
            'id': str(uuid.uuid4()),
            'title': '每日冥想练习',
            'description': '建立每日冥想的习惯',
            'period': '2026-01',
            'deadline': int((TODAY + timedelta(days=30)).timestamp()),
            'status': 'active',
            'calculated_progress': 60.0,
        },
    ]

    for obj in objectives_data:
        cursor.execute("""
            INSERT INTO objectives
            (id, title, description, period, deadline, status, calculated_progress, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            obj['id'], obj['title'], obj['description'], obj['period'],
            obj['deadline'], obj['status'], obj['calculated_progress'],
            TODAY.isoformat()
        ))

    print(f"✅ 插入了 {len(objectives_data)} 个目标")

    # ========== 2. 创建关键结果 (KeyResults) ==========
    key_results_data = [
        # 目标1的KR
        {
            'id': str(uuid.uuid4()),
            'objective_id': objectives_data[0]['id'],
            'title': '阅读完整本书',
            'type': 'percent',
            'start_val': 0.0,
            'target_val': 100.0,
            'current_val': 30.0,
            'unit': '%',
        },
        {
            'id': str(uuid.uuid4()),
            'objective_id': objectives_data[0]['id'],
            'title': '撰写笔记章节',
            'type': 'number',
            'start_val': 0.0,
            'target_val': 10.0,
            'current_val': 2.0,
            'unit': '章',
        },
        # 目标2的KR
        {
            'id': str(uuid.uuid4()),
            'objective_id': objectives_data[1]['id'],
            'title': '完成核心功能',
            'type': 'number',
            'start_val': 0.0,
            'target_val': 5.0,
            'current_val': 2.0,
            'unit': '个',
        },
        {
            'id': str(uuid.uuid4()),
            'objective_id': objectives_data[1]['id'],
            'title': '编写单元测试',
            'type': 'percent',
            'start_val': 0.0,
            'target_val': 100.0,
            'current_val': 45.0,
            'unit': '%',
        },
        # 目标3的KR
        {
            'id': str(uuid.uuid4()),
            'objective_id': objectives_data[2]['id'],
            'title': '完成冥想天数',
            'type': 'number',
            'start_val': 0.0,
            'target_val': 30.0,
            'current_val': 18.0,
            'unit': '天',
        },
    ]

    for kr in key_results_data:
        cursor.execute("""
            INSERT INTO key_results
            (id, objective_id, title, type, start_val, target_val, current_val, unit, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            kr['id'], kr['objective_id'], kr['title'], kr['type'],
            kr['start_val'], kr['target_val'], kr['current_val'], kr['unit'],
            TODAY.isoformat()
        ))

    print(f"✅ 插入了 {len(key_results_data)} 个关键结果")

    # ========== 3. 创建任务 (Tasks) ==========
    tasks_data = [
        # KR1的任务
        {
            'id': str(uuid.uuid4()),
            'kr_id': key_results_data[0]['id'],
            'title': '阅读第1-3章',
            'status': 'done',
        },
        {
            'id': str(uuid.uuid4()),
            'kr_id': key_results_data[0]['id'],
            'title': '阅读第4-6章',
            'status': 'in_progress',
        },
        # KR2的任务
        {
            'id': str(uuid.uuid4()),
            'kr_id': key_results_data[1]['id'],
            'title': '撰写第一章笔记',
            'status': 'done',
        },
        # KR3的任务
        {
            'id': str(uuid.uuid4()),
            'kr_id': key_results_data[2]['id'],
            'title': '实现番茄钟功能',
            'status': 'done',
        },
        {
            'id': str(uuid.uuid4()),
            'kr_id': key_results_data[2]['id'],
            'title': '实现可视化组件',
            'status': 'in_progress',
        },
        # KR5的任务
        {
            'id': str(uuid.uuid4()),
            'kr_id': key_results_data[4]['id'],
            'title': '早晨冥想',
            'status': 'done',
        },
    ]

    for task in tasks_data:
        cursor.execute("""
            INSERT INTO tasks
            (id, kr_id, title, status, created_at)
            VALUES (?, ?, ?, ?, ?)
        """, (
            task['id'], task['kr_id'], task['title'], task['status'],
            TODAY.isoformat()
        ))

    print(f"✅ 插入了 {len(tasks_data)} 个任务")

    # ========== 4. 创建今天的专注会话 (FocusSessions) ==========
    # 时间分布：8:00-22:00，不同的效率评分
    sessions_config = [
        {'hour': 8, 'minute': 0, 'task_idx': 0, 'quality': 4, 'duration': 25},  # 高效
        {'hour': 8, 'minute': 30, 'task_idx': 0, 'quality': 5, 'duration': 25}, # 完美流
        {'hour': 10, 'minute': 0, 'task_idx': 1, 'quality': 3, 'duration': 25}, # 一般
        {'hour': 10, 'minute': 35, 'task_idx': 1, 'quality': 2, 'duration': 25}, # 分心
        {'hour': 14, 'minute': 0, 'task_idx': 3, 'quality': 5, 'duration': 25}, # 完美流
        {'hour': 14, 'minute': 30, 'task_idx': 3, 'quality': 4, 'duration': 25}, # 高效
        {'hour': 16, 'minute': 0, 'task_idx': 4, 'quality': 3, 'duration': 25}, # 一般
        {'hour': 19, 'minute': 0, 'task_idx': 5, 'quality': 4, 'duration': 25}, # 高效
        {'hour': 19, 'minute': 35, 'task_idx': 5, 'quality': 5, 'duration': 25}, # 完美流
        {'hour': 21, 'minute': 0, 'task_idx': 1, 'quality': 2, 'duration': 20}, # 疲惫
    ]

    sessions_data = []
    for config in sessions_config:
        start_time = TODAY.replace(
            hour=config['hour'],
            minute=config['minute']
        )
        end_time = start_time + timedelta(minutes=config['duration'])

        session = {
            'id': str(uuid.uuid4()),
            'task_id': tasks_data[config['task_idx']]['id'],
            'start_time': int(start_time.timestamp()),
            'end_time': int(end_time.timestamp()),
            'duration_seconds': config['duration'] * 60,
            'type': 'work',
            'status': 'completed',
            'focus_quality': config['quality'],
            'review_note': f"专注质量: {config['quality']}/5",
        }
        sessions_data.append(session)

    for session in sessions_data:
        cursor.execute("""
            INSERT INTO focus_sessions
            (id, task_id, start_time, end_time, duration_seconds, type, status, focus_quality, review_note, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            session['id'], session['task_id'], session['start_time'],
            session['end_time'], session['duration_seconds'], session['type'],
            session['status'], session['focus_quality'], session['review_note'],
            TODAY.isoformat()
        ))

    print(f"✅ 插入了 {len(sessions_data)} 个专注会话")

    # ========== 5. 创建杂念记录 (Thoughts) ==========
    thoughts_data = [
        {
            'id': str(uuid.uuid4()),
            'session_id': sessions_data[3]['id'],  # 低效率会话的杂念
            'content': '想起下午要开会',
            'type': 'distraction',
            'is_resolved': 0,
        },
        {
            'id': str(uuid.uuid4()),
            'session_id': sessions_data[3]['id'],
            'content': '手机震动，收到消息',
            'type': 'distraction',
            'is_resolved': 1,
        },
        {
            'id': str(uuid.uuid4()),
            'session_id': sessions_data[9]['id'],
            'content': '有点累了，想休息',
            'type': 'distraction',
            'is_resolved': 0,
        },
        {
            'id': str(uuid.uuid4()),
            'session_id': None,
            'content': '记得买牛奶',
            'type': 'todo',
            'is_resolved': 0,
        },
        {
            'id': str(uuid.uuid4()),
            'session_id': sessions_data[4]['id'],
            'content': '这个算法可以优化',
            'type': 'idea',
            'is_resolved': 0,
        },
    ]

    for thought in thoughts_data:
        cursor.execute("""
            INSERT INTO thoughts
            (id, session_id, content, type, is_resolved, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            thought['id'], thought['session_id'], thought['content'],
            thought['type'], thought['is_resolved'], TODAY.isoformat()
        ))

    print(f"✅ 插入了 {len(thoughts_data)} 个杂念记录")

    conn.commit()
    print("\n🎉 所有模拟数据插入完成！")

    # 打印统计信息
    print("\n📊 数据统计：")
    print(f"  - 目标 (Objectives): {len(objectives_data)}")
    print(f"  - 关键结果 (KeyResults): {len(key_results_data)}")
    print(f"  - 任务 (Tasks): {len(tasks_data)}")
    print(f"  - 专注会话 (FocusSessions): {len(sessions_data)}")
    print(f"  - 杂念记录 (Thoughts): {len(thoughts_data)}")

    # 计算今日有效时间
    total_effective_mins = sum([
        (s['duration_seconds'] / 60) * (s['focus_quality'] / 5.0)
        for s in sessions_data
    ])
    print(f"\n⏰ 今日有效时间: {total_effective_mins:.1f} 分钟 (质量加权)")


def main():
    """主函数"""
    print(f"📅 模拟日期: {TODAY.strftime('%Y-%m-%d')}")
    print(f"🗄️  数据库文件: {DB_PATH}\n")

    # 连接数据库
    conn = sqlite3.connect(DB_PATH)

    try:
        # 创建表
        create_tables(conn)

        # 插入数据
        insert_mock_data(conn)

    except Exception as e:
        print(f"❌ 错误: {e}")
        conn.rollback()
    finally:
        conn.close()

    print(f"\n✨ 数据库文件已生成: {DB_PATH}")
    print("💡 提示: 将此文件复制到应用数据目录即可查看效果")


if __name__ == "__main__":
    main()
