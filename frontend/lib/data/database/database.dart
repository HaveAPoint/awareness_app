import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Objectives,
    KeyResults,
    KeyResultCheckIns, // 新增
    Tasks,
    FocusSessions,
    Thoughts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // 升级版本号

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // 开发阶段简单粗暴：如果表结构变动太大，建议在开发机上直接卸载 APP 重装
      // 生产环境需要写详细的 addColumn 逻辑
      if (from < 3) {
        // 尝试创建新表 (如果是旧版升级上来)
        await m.createTable(keyResultCheckIns);

        // 注意：如果是给现有表加字段 (如 Objectives.calculatedProgress)，
        // 需要使用 await m.addColumn(objectives, objectives.calculatedProgress);
        // 为了开发简便，建议直接卸载 APP 让 onCreate 重新跑
      }
    },
  );

  // --- 🌟 OKR 核心业务逻辑 (事务处理) ---

  /// 添加一次进度打卡 (Check-In)
  /// 1. 插入历史记录
  /// 2. 更新 KR 当前值
  /// 3. 自动重算 Objective 总进度
  Future<void> addCheckIn({
    required String krId,
    required double newValue,
    String? comment,
    int? confidence,
  }) {
    return transaction(() async {
      // 1. 插入记录
      await into(keyResultCheckIns).insert(
        KeyResultCheckInsCompanion.insert(
          krId: krId,
          value: newValue,
          comment: Value(comment),
          confidence: Value(confidence),
        ),
      );

      // 2. 更新 KeyResult
      final kr = await (select(
        keyResults,
      )..where((t) => t.id.equals(krId))).getSingle();

      await (update(keyResults)..where((t) => t.id.equals(krId))).write(
        KeyResultsCompanion(
          currentVal: Value(newValue),
          updatedAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ),
      );

      // 3. 触发重算
      await _recalculateObjectiveProgress(kr.objectiveId);
    });
  }

  /// 内部方法：加权计算 Objective 进度
  Future<void> _recalculateObjectiveProgress(String objectiveId) async {
    final krs = await (select(
      keyResults,
    )..where((t) => t.objectiveId.equals(objectiveId))).get();

    if (krs.isEmpty) return;

    double totalWeight = 0.0;
    double weightedProgressSum = 0.0;

    for (final kr in krs) {
      // 计算单个 KR 进度 (0.0 - 1.0)
      double span = kr.targetVal - kr.startVal;
      double progress = 0.0;

      if (span.abs() > 0.0001) {
        // (当前 - 起始) / (目标 - 起始)
        progress = (kr.currentVal - kr.startVal) / span;
      } else {
        // 目标值等于起始值的情况
        progress = kr.currentVal >= kr.targetVal ? 1.0 : 0.0;
      }

      // 限制在 0-1 之间 (防止溢出，除非你允许 >100%)
      // progress = progress.clamp(0.0, 1.0);

      weightedProgressSum += progress * kr.weight;
      totalWeight += kr.weight;
    }

    final finalProgress = totalWeight == 0
        ? 0.0
        : (weightedProgressSum / totalWeight) * 100;

    // 更新 Objective
    await (update(objectives)..where((t) => t.id.equals(objectiveId))).write(
      ObjectivesCompanion(
        calculatedProgress: Value(finalProgress),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  // --- 基础 CRUD ---

  /// 获取所有未处理的活跃念头
  Future<List<Thought>> getAllActiveThoughts() {
    return (select(thoughts)
          ..where((t) => t.isResolved.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取收件箱中的念头（category='inbox'）
  Future<List<Thought>> getInboxThoughts() {
    return (select(thoughts)
          ..where((t) => t.category.equals('inbox'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 插入新念头
  Future<int> insertThought(ThoughtsCompanion entry) {
    return into(thoughts).insert(entry);
  }

  /// 标记念头为已处理
  Future<void> defuseThought(String id) async {
    await (update(thoughts)..where((t) => t.id.equals(id))).write(
      ThoughtsCompanion(
        isResolved: const Value(true),
        resolvedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isSynced: const Value(false),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    // 换了个数据库文件名，避免和旧版本冲突，保证全新的表结构生效
    final file = File(p.join(dbFolder.path, 'awareness_v3.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
