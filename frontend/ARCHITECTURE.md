## 觉知系统 (Awareness System) - v2 数据流架构

### 📊 完整数据流拓扑

```
┌─────────────────────────────────────────────────────────────────┐
│                        App 入口                                  │
│  main.dart → AppDatabase 初始化 → DashboardPage               │
└────────┬────────────────────────────────────────────────────────┘
         │
         ├─ 分支1: FocusPage (专注模式)
         │  ├─ UI: 番茄钟倒计时/正计时（由 FocusController 驱动）
         │  └─ 交互: 快速捕捉（Quick Capture）
         │     ├─ 触发: 点击悬浮按钮 / 快捷入口
         │     └─ 写入: db.insertThought(...)（不中断计时，不弹出列表）
         │
         ├─ 分支2: JournalPage（重构目标：每日存在感容器）
         │  ├─ 顶部：意图发射台 (Launchpad)
         │  │  ├─ 单击：展开/折叠（确认“我到底要做什么”）
         │  │  └─ 长按：投入/承诺 → 跳转到分支1 (FocusPage)
         │  ├─ 中部：诚实的镜子 (Mirror)
         │  │  ├─ 裂口摘要 → 展开为“今日时间轴/记录列表”
         │  │  └─ 批量评分：对已完成专注记录进行评价（完成复盘闭环）
         │  └─ 底部：思维沉淀池 (Sediment)
         │     ├─ 快速输入：输入→回车→继续（最小打断）
         │     └─ 勾选完成：下沉动画 → 归档 (Archive)
         │
         └─ 分支3: Goals (目标) - 占位符
```

### 🗄️ 数据库层 (Data Layer)

#### 表结构
```
Thoughts (念头表)
├─ id (TEXT, PK)             - 唯一标识符 (UUID)
├─ sessionId (TEXT, FK, 可空) - 关联的专注时段
├─ content (TEXT)            - 内容
├─ type (TEXT)               - 类型: 'distraction' | 'idea' | 'todo'
├─ isResolved (BOOL)         - 是否已处理/归档
├─ createdAt (DATETIME)      - 创建时间
└─ isSynced (BOOL)           - 是否已同步

FocusSessions (专注时段表 - 预留)
├─ id (TEXT, PK)
├─ taskId (TEXT, FK)
├─ startTime (INT)
├─ endTime (INT, 可空)
├─ durationSeconds (INT)
├─ type (TEXT)               - 'work' | 'short_break' | 'long_break'
├─ status (TEXT)
├─ focusQuality (INT, 可空)  - 1-5 星
├─ reviewNote (TEXT, 可空)
└─ (sync fields) createdAt/updatedAt/isSynced

Tasks (任务表 - 预留)
├─ id (TEXT, PK)
├─ title (TEXT)
├─ krId (TEXT, FK, 可空)
├─ estPomodoros (INT)
└─ ...

KeyResults & Objectives - OKR 结构
```

#### DAO 方法 (AppDatabase)
```dart
// 查询接口
Future<List<Thought>> getAllActiveThoughts()
Future<List<Thought>> getInboxThoughts()

//（计划/建议）镜像层复盘接口
// Future<List<FocusSession>> getUnreviewedFocusSessions()
// Future<void> reviewFocusSession(...)

// 写入接口
Future<int> insertThought(ThoughtsCompanion entry)
Future<void> defuseThought(String uuid)
```

### 🎮 逻辑层 (Logic Layer)

#### FocusController (lib/logic/timer/focus_controller.dart)
- 职责: 番茄钟状态机 + 倒计时/正计时 + 工作/短休/长休循环
- 输出: 当前状态、剩余/超时秒数、循环步骤（用于 UI 展示与后续 FocusSession 记录）

### 🎨 UI 层 (UI Layer)

#### 页面流程
1. **DashboardPage** (根导航)
   - 底部导航栏切换三个标签页
   
2. **FocusPage** (专注)
  - 显示倒计时/正计时（FocusController）
  - 快速捕捉入口：弹出极简输入框，回车即写入 `Thoughts`
  - 原“切碎/游戏化拦截”相关 UI 已移除（若有残留文件，仅视为历史遗留，不属于当前运行链路）

3. **JournalPage**（分支二：每日存在感容器）
  - 顶部：意图发射台（长按跳转分支一）
  - 中部：镜像裂口（查看记录/批量评分）
  - 底部：沉淀池（未归档捕捉项列表 + 勾选归档）

### 🔄 数据流循环示例

#### 流程 A: 在专注页快速捕捉念头 (Quick Capture)
```
1. FocusPage 计时进行中
2. 用户点击“快速捕捉”入口
3. 弹出极简输入框（不展示历史列表）
4. 用户输入 → 回车/提交
5. → db.insertThought(ThoughtsCompanion(...)) 写入
6. ✓ 输入框消失/清空，计时不中断
```

#### 流程 B: 在收件箱中处理念头
```
1. 分支二（JournalPage）底部“沉淀池”展示未归档捕捉项
2. → db.getInboxThoughts() 查询（MVP 约定：type='todo'）
3. → ListView 渲染列表
4. 用户点击某项的 ✓
5. → db.defuseThought(id)
6. ✓ 下沉动画 → 归档，列表刷新
```

#### 流程 C: 快速录入念头
```
（目标交互，作为分支二“沉淀池”的快速入口）
1. 用户在沉淀池的输入框输入文本
2. 回车/提交
3. → db.insertThought(...)
4. ✓ 输入框清空，列表新增一条未归档项
```

### 📦 组件依赖关系

```
UI 层:
  main.dart
    └─ DashboardPage
       ├─ FocusPage
       ├─ JournalPage
       └─ GoalsPage (占位)

逻辑层:
  FocusController
    └─ 输出计时状态与循环步骤

通用组件:
  （以当前实现为准：与“切碎/刀光/粒子”相关组件不再属于核心链路）

数据层:
  AppDatabase (Drift)
    ├─ Tables (Thoughts, Tasks, FocusSessions, ...)
    └─ DAO 方法

模型层:
  lib/data/database/tables.dart
    ├─ Thoughts (Drift table)
    ├─ Thought (生成的类)
    └─ ThoughtsCompanion
```

### ✅ 数据流验证清单

- [x] **入口初始化**: main.dart → AppDatabase → DashboardPage
- [x] **页面导航**: DashboardPage → FocusPage/JournalPage
- [ ] **快速捕捉**: FocusPage 快速输入 → db.insertThought() → UI 不中断
- [x] **收件箱管理**: JournalPage 查询 → ListView 展示 → 处理操作
- [x] **快速录入**: FAB → 对话框 → 数据库插入 → 列表刷新
- [x] **同步预留**: 所有表都有 `updated_at` 和 `is_synced` 字段

### 🎯 下一步 (未来迭代)

1. **番茄钟实现**: 在 FocusPage 添加真实的 Timer 逻辑
2. **OKR 管理**: 实现 Objectives/KeyResults 的 CRUD
3. **FocusSession 记录**: 番茄钟开始时创建 Session，结束时更新（供“镜像层”批量评分）
4. **同步服务**: 实现 SyncService，对接 Python FastAPI 后端
5. **数据分析**: 日结页面展示今日的"专注度"和"杂念统计"

---

**架构特点**:
- ✅ 离线优先：所有读写都是本地 SQLite
- ✅ 低阻力：UI 响应快速，逻辑与界面分离
- ✅ 同步就绪：UUID 主键 + 同步字段，为云端准备
- ✅ 模块化：每层职责清晰，易于测试和扩展
