## 觉知系统 (Awareness System) - v2 数据流架构

### 📊 完整数据流拓扑

```
┌─────────────────────────────────────────────────────────────────┐
│                        App 入口                                  │
│  main.dart → AppDatabase 初始化 → DashboardPage               │
└────────┬────────────────────────────────────────────────────────┘
         │
         ├─ 分支1: FocusPage (专注模式)
         │  ├─ UI: 番茄钟倒计时 (占位)
         │  └─ 交互: "捕捉念头" 按钮
         │     └─ 触发 _showInterceptor()
         │        ├─ 从 DB 读取: db.getAllActiveThoughts()
         │        └─ 弹出 InterceptorOverlay
         │           └─ GameController 游戏循环
         │              ├─ 物理更新: update()
         │              ├─ 划动处理: addBladePoint()
         │              └─ 念头切碎回调: onDefuse → db.defuseThought(uuid)
         │
         ├─ 分支2: JournalPage (日记/收件箱)
         │  ├─ 加载: db.getInboxThoughts()
         │  ├─ 显示: ListView 列表
         │  └─ 交互: 点击 ✓ 标记处理
         │     └─ db.defuseThought(uuid)
         │
         └─ 分支3: Goals (目标) - 占位符
```

### 🗄️ 数据库层 (Data Layer)

#### 表结构
```
Thoughts (念头表)
├─ uuid (TEXT, PK)           - 唯一标识符
├─ content (TEXT)            - 念头内容
├─ category (TEXT)           - 分类: 'inbox', 'distraction', 'insight'
├─ isResolved (BOOL)         - 是否已处理
├─ sessionId (TEXT, FK)      - 关联的专注时段 (可空)
├─ resolvedAt (INT)          - 处理时间戳
├─ created_at (DATETIME)     - 创建时间
├─ updated_at (DATETIME)     - 更新时间
├─ is_synced (BOOL)          - 是否已同步
└─ latitude/longitude (REAL) - 地理信息 (可选)

FocusSessions (专注时段表 - 预留)
├─ id (TEXT, PK)
├─ taskId (TEXT, FK)
├─ startTime (INT)
├─ endTime (INT, 可空)
├─ duration (INT)
├─ status (TEXT)
└─ ...

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

// 写入接口
Future<int> insertThought(ThoughtsCompanion entry)
Future<void> defuseThought(String uuid)
```

### 🎮 逻辑层 (Logic Layer)

#### GameController (lib/logic/interceptor/game_controller.dart)
- 职责: 纯业务逻辑，无 UI 依赖
- 关键方法:
  - `update(screenW, screenH)` - 每帧调用，更新物理
  - `addBladePoint(point)` - 处理划动点
  - `onDefuse` - 回调函数，当念头被切碎时触发

### 🎨 UI 层 (UI Layer)

#### 页面流程
1. **DashboardPage** (根导航)
   - 底部导航栏切换三个标签页
   
2. **FocusPage** (专注)
   - 显示倒计时 (目前静态)
   - "捕捉念头" 按钮
   - 点击时: 
     ```dart
     final thoughts = await db.getAllActiveThoughts();
     showGeneralDialog(
       pageBuilder: (...) => InterceptorOverlay(
         thoughts: thoughts,
         onDefuse: (uuid) => db.defuseThought(uuid),
       )
     );
     ```

3. **InterceptorOverlay** (念头拦截弹窗)
   - 使用 GameController 管理游戏状态
   - 每帧调用 `_controller.update(width, height)`
   - 绘制: BladePainter (刀光) + ParticlePainter (粒子)

4. **JournalPage** (日记/收件箱)
   - 查询: `db.getInboxThoughts()`
   - 列表项操作: 点击 ✓ 时调用 `db.defuseThought(uuid)`

### 🔄 数据流循环示例

#### 流程 A: 在拦截弹窗中切碎念头
```
1. 用户划动屏幕
2. InterceptorOverlay.onPanUpdate()
3. → GameController.addBladePoint()
4. → _checkCollision() 检测碰撞
5. → 碰撞命中 → _onSliceTrouble()
6. → 触发 onDefuse(uuid) 回调
7. → db.defuseThought(uuid) 写入数据库
8. ✓ 念头从数据库中标记为已处理
9. ✓ 下次打开拦截弹窗时不再显示该念头
```

#### 流程 B: 在收件箱中处理念头
```
1. JournalPage 打开
2. → db.getInboxThoughts() 查询所有 category='inbox' 的念头
3. → ListView 渲染列表
4. 用户点击某项的 ✓ 按钮
5. → db.defuseThought(uuid)
6. ✓ 刷新列表，念头消失
```

#### 流程 C: 快速录入念头
```
1. JournalPage FAB (+ 按钮)
2. → _showAddDialog()
3. 用户输入文本
4. → db.insertThought(ThoughtsCompanion(
     uuid: Uuid().v4(),
     content: userText,
     category: 'inbox',
   ))
5. ✓ 新念头写入数据库
6. ✓ 刷新列表显示
```

### 📦 组件依赖关系

```
UI 层:
  main.dart
    └─ DashboardPage
       ├─ FocusPage
       │  └─ InterceptorOverlay
       │     ├─ GameController (逻辑层)
       │     ├─ BladePainter (通用组件)
       │     └─ ParticlePainter (通用组件)
       ├─ JournalPage
       └─ GoalsPage (占位)

逻辑层:
  GameController
    └─ 使用 Thought 模型
    └─ 回调: onDefuse(uuid)

通用组件:
  BladePainter
  ParticlePainter
  (其他特效)

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
- [x] **弹窗打开**: FocusPage.捕捉念头 → 读数据 → InterceptorOverlay
- [x] **游戏循环**: Ticker → GameController.update() → setState()
- [x] **念头切碎**: 划动 → 碰撞检测 → onDefuse 回调 → DB 写入
- [x] **收件箱管理**: JournalPage 查询 → ListView 展示 → 处理操作
- [x] **快速录入**: FAB → 对话框 → 数据库插入 → 列表刷新
- [x] **同步预留**: 所有表都有 `updated_at` 和 `is_synced` 字段

### 🎯 下一步 (未来迭代)

1. **番茄钟实现**: 在 FocusPage 添加真实的 Timer 逻辑
2. **OKR 管理**: 实现 Objectives/KeyResults 的 CRUD
3. **FocusSession 记录**: 拦截弹窗运行时创建 Session，结束时更新
4. **同步服务**: 实现 SyncService，对接 Python FastAPI 后端
5. **数据分析**: 日结页面展示今日的"专注度"和"杂念统计"

---

**架构特点**:
- ✅ 离线优先：所有读写都是本地 SQLite
- ✅ 低阻力：UI 响应快速，逻辑与界面分离
- ✅ 同步就绪：UUID 主键 + 同步字段，为云端准备
- ✅ 模块化：每层职责清晰，易于测试和扩展
