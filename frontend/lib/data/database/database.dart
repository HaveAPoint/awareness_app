import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
    Tags,
    TaskTags,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6; // 升级版本号

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // 架构变动较大，建议开发环境直接使用新的数据库文件。
      // 如需保留历史数据，请补充迁移逻辑。
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

  // --- 目标状态自动管理 ---

  /// 自动将过期的active目标转为completed状态
  /// 归档(archived)需要手动处理
  Future<void> autoCompleteExpiredObjectives() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // 查找所有已过期但仍是active状态的目标
    final expiredObjectives = await (select(objectives)
          ..where((t) => t.status.equals('active') & t.deadline.isSmallerThanValue(now)))
        .get();
    
    if (expiredObjectives.isEmpty) return;
    
    // 批量更新为completed状态
    for (final obj in expiredObjectives) {
      await (update(objectives)..where((t) => t.id.equals(obj.id))).write(
        ObjectivesCompanion(
          status: const Value('completed'),
          updatedAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ),
      );
    }
    
    debugPrint('[Database] 自动完成 ${expiredObjectives.length} 个过期目标');
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
          ..where((t) => t.type.equals('todo'))
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
        isSynced: const Value(false),
      ),
    );
  }

  // --- 应用设置：工作时长秒数 ---
  Future<int?> getTimerDurationSeconds() async {
    try {
      final row =
          await (select(appSettings)
                ..where((t) => t.key.equals('timer_duration_seconds')))
              .getSingleOrNull();
      debugPrint(
        '[Database] getTimerDurationSeconds: row=$row, value=${row?.value}',
      );
      return row?.value;
    } catch (e, stackTrace) {
      debugPrint('[Database] ❌ getTimerDurationSeconds 出错: $e');
      debugPrint('[Database] 堆栈: $stackTrace');
      return null;
    }
  }

  Future<void> setTimerDurationSeconds(int seconds) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSetting(key: 'timer_duration_seconds', value: seconds),
    );
  }

  // --- 应用设置：休息时长秒数 ---
  Future<int?> getRestDurationSeconds() async {
    try {
      final row = await (select(
        appSettings,
      )..where((t) => t.key.equals('rest_duration_seconds'))).getSingleOrNull();
      debugPrint(
        '[Database] getRestDurationSeconds: row=$row, value=${row?.value}',
      );
      return row?.value;
    } catch (e, stackTrace) {
      debugPrint('[Database] ❌ getRestDurationSeconds 出错: $e');
      debugPrint('[Database] 堆栈: $stackTrace');
      return null;
    }
  }

  Future<void> setRestDurationSeconds(int seconds) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSetting(key: 'rest_duration_seconds', value: seconds),
    );
  }

  // --- 应用设置：长休息时长秒数 ---
  Future<int?> getLongRestDurationSeconds() async {
    try {
      final row =
          await (select(appSettings)
                ..where((t) => t.key.equals('long_rest_duration_seconds')))
              .getSingleOrNull();
      debugPrint(
        '[Database] getLongRestDurationSeconds: row=$row, value=${row?.value}',
      );
      return row?.value;
    } catch (e, stackTrace) {
      debugPrint('[Database] ❌ getLongRestDurationSeconds 出错: $e');
      debugPrint('[Database] 堆栈: $stackTrace');
      return null;
    }
  }

  Future<void> setLongRestDurationSeconds(int seconds) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSetting(key: 'long_rest_duration_seconds', value: seconds),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    // 换了个数据库文件名，避免和旧版本冲突，保证全新的表结构生效
    final file = File(p.join(dbFolder.path, 'awareness_v6.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
