import 'package:drift/drift.dart';

import 'package:uuid/uuid.dart';

// --- 1. 目标与任务域 (OKR Domain) ---

class Objectives extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();

  // 优化：增加周期字段，便于筛选 (e.g., "2024-Q1", "2024-Year")
  TextColumn get period => text().nullable()();

  IntColumn get deadline => integer()(); // UNIX timestamp
  // 建议使用 int 配合 Dart Enum，但在数据库层 text 具备更好的可读性
  TextColumn get status => text().withDefault(const Constant('active'))();
  // 缓存进度
  RealColumn get calculatedProgress =>
      real().withDefault(const Constant(0.0))();
  // 目标颜色 (Hex string, e.g., "0xFFF6AD55")
  TextColumn get color => text().nullable()();
  // Sync fields
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class KeyResults extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get objectiveId =>
      text().references(Objectives, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();

  // type: 'number', 'boolean', 'percent', 'currency'
  TextColumn get type => text().withDefault(const Constant('number'))();
  RealColumn get startVal => real().withDefault(const Constant(0.0))();
  RealColumn get targetVal => real()();
  RealColumn get currentVal => real()();
  TextColumn get unit => text().nullable()();
  RealColumn get weight => real().withDefault(const Constant(1.0))();
  // Sync fields
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

// 进展记录 (不变，设计得很好)
class KeyResultCheckIns extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get krId =>
      text().references(KeyResults, #id, onDelete: KeyAction.cascade)();
  RealColumn get value => real()();
  TextColumn get comment => text().nullable()();
  IntColumn get confidence => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();

  // 允许 Task 不关联 KR (比如杂事 Inbox)，设为 nullable
  TextColumn get krId => text().nullable().references(
    KeyResults,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get title => text()();

  // 优化：预估 vs 实际 -> 用于计算“预估偏差率”
  IntColumn get estPomodoros => integer().withDefault(const Constant(1))();
  IntColumn get actualPomodoros => integer().withDefault(const Constant(0))();
  // 优先级：1-Low, 2-Medium, 3-High
  IntColumn get priority => integer().withDefault(const Constant(2))();
  TextColumn get status => text().withDefault(const Constant('todo'))();
  // Sync fields
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

// --- 2. 觉知与执行域 (Awareness & Execution Domain) ---

class FocusSessions extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();

  // Session 可以关联 Task，也可以是无目的的自由专注 (nullable)
  TextColumn get taskId => text().nullable().references(Tasks, #id)();

  IntColumn get startTime => integer()();
  IntColumn get endTime => integer().nullable()();

  // 实际专注时长 (秒)
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();

  // 🔥 新增：Session 类型，区分专注和休息
  // 'work', 'short_break', 'long_break'
  TextColumn get type => text().withDefault(const Constant('work'))();
  // 🔥 新增：专注后的直接反思 (Review Loop)
  // 完成状态: 'completed', 'abandoned' (中途放弃)
  TextColumn get status => text()();
  // 专注质量打分: 1-5 星
  IntColumn get focusQuality => integer().nullable()();
  // 简短反思: "刚才有点走神，因为手机震动"
  TextColumn get reviewNote => text().nullable()();
  // Sync fields
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Thoughts extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get sessionId =>
      text().nullable().references(FocusSessions, #id)();
  TextColumn get content => text()();

  // 优化：明确类别，便于区分是“干扰”还是“灵感”
  // 'distraction' (内部/外部干扰), 'idea' (灵感), 'todo' (临时想到的待办)
  TextColumn get type => text().withDefault(const Constant('distraction'))();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

// --- 3. 配置与标签 (System) ---

// 建议增加 Tag 表，用于跨越 KR 的多维度管理 (比如 #Reading #DeepWork)
class Tags extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()(); // Hex string

  @override
  Set<Column> get primaryKey => {id};
}

// 多对多关联：Tasks <-> Tags
class TaskTags extends Table {
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {taskId, tagId};
}

// --- 4. 应用级设置 (Key-Value) ---
class AppSettings extends Table {
  TextColumn get key => text()(); // 如: 'timer_duration_seconds'
  IntColumn get value => integer()(); // 通用存储，这里用于秒数

  @override
  Set<Column> get primaryKey => {key};
}
