import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// --- 1. 目标与任务域 (OKR Domain) ---

class Objectives extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()(); // 新增：目标描述
  IntColumn get deadline => integer()(); // UNIX timestamp
  TextColumn get status => text()(); // 'active', 'archived', 'completed'

  // 新增：缓存计算后的总进度 (0.0 - 100.0)，由 Check-in 触发自动更新
  RealColumn get calculatedProgress =>
      real().withDefault(const Constant(0.0))();

  // Sync fields
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class KeyResults extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  // 级联删除：如果目标删了，KR 也自动删
  TextColumn get objectiveId =>
      text().references(Objectives, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();

  // 核心数值逻辑优化
  // type: 'number', 'boolean', 'percent', 'currency'
  TextColumn get type => text().withDefault(const Constant('number'))();

  // 比如减肥：从 80(start) 到 70(target)，当前 75(current)
  RealColumn get startVal => real().withDefault(const Constant(0.0))();
  RealColumn get targetVal => real()();
  RealColumn get currentVal => real()();

  TextColumn get unit => text().nullable()(); // "个", "kg", "%"

  // 权重：默认 1.0。如果这个 KR 特别重要，可以设为 2.0
  RealColumn get weight => real().withDefault(const Constant(1.0))();

  // Sync fields
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 🔥 新增表：进展记录 (Check-in History)
// 用于生成燃尽图，记录每一次的努力
class KeyResultCheckIns extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get krId =>
      text().references(KeyResults, #id, onDelete: KeyAction.cascade)();

  RealColumn get value => real()(); // 打卡时的数值
  TextColumn get comment => text().nullable()(); // 复盘心得
  IntColumn get confidence => integer().nullable()(); // 信心指数 (0-100)

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get krId =>
      text().nullable().references(KeyResults, #id)(); // 关联 KR
  TextColumn get title => text()();
  IntColumn get estPomodoros => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(
    const Constant('todo'),
  )(); // 'todo', 'in_progress', 'done'

  // Sync fields
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- 2. 觉知与执行域 (Awareness & Execution Domain) ---

class FocusSessions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get taskId => text().references(Tasks, #id)();
  IntColumn get startTime => integer()(); // UNIX timestamp
  IntColumn get endTime => integer().nullable()();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  TextColumn get status => text()(); // 'completed', 'interrupted'
  IntColumn get energyLog => integer().nullable()(); // 1-10

  // Sync fields
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Thoughts extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get sessionId =>
      text().nullable().references(FocusSessions, #id)();
  TextColumn get content => text()();
  TextColumn get category => text().withDefault(
    const Constant('inbox'),
  )(); // 'distraction', 'inbox', 'insight'

  // 状态字段
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
  IntColumn get resolvedAt => integer().nullable()(); // UNIX timestamp

  // Sync fields
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  // Location
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
