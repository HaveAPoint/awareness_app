import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/goal_models.dart';

/// OKR 仓储层 - 负责 Objectives 和 KeyResults 的数据持久化
class GoalRepository {
  final AppDatabase _db;

  GoalRepository(this._db);

  // --- Objective CRUD ---

  /// 获取所有活跃的目标
  Future<List<ObjectiveModel>> getAllObjectives() async {
    final objectives =
        await (_db.select(_db.objectives)
              ..where((t) => t.status.equals('active'))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();

    final result = <ObjectiveModel>[];

    for (final obj in objectives) {
      final krs = await _getKeyResultsForObjective(obj.id);
      result.add(_objectiveFromDb(obj, krs));
    }

    return result;
  }

  /// 根据 ID 获取单个目标
  Future<ObjectiveModel?> getObjectiveById(String id) async {
    final obj = await (_db.select(
      _db.objectives,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (obj == null) return null;

    final krs = await _getKeyResultsForObjective(obj.id);
    return _objectiveFromDb(obj, krs);
  }

  /// 创建新目标（带关键结果）
  Future<String> createObjective({
    required String title,
    String? description,
    String? period,
    required int deadline,
    required List<Map<String, dynamic>> keyResults,
    int priority = 2,
    String? owner,
  }) async {
    return await _db.transaction(() async {
      // 1. 插入 Objective
      final objId = await _db
          .into(_db.objectives)
          .insert(
            ObjectivesCompanion.insert(
              title: title,
              description: Value(description),
              period: Value(period),
              deadline: deadline,
              status: const Value('active'),
            ),
          );

      // 2. 获取插入后的对象（drift insert 返回的是行号，需要查询获取 id）
      final insertedObjs =
          await (_db.select(_db.objectives)
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
                ..limit(1))
              .get();

      final insertedObj = insertedObjs.first;

      // 3. 插入关联的 KeyResults
      for (final kr in keyResults) {
        await _db
            .into(_db.keyResults)
            .insert(
              KeyResultsCompanion.insert(
                objectiveId: insertedObj.id,
                title: kr['title'] as String,
                type: Value(kr['type'] as String? ?? 'number'),
                startVal: Value(kr['startVal'] as double? ?? 0.0),
                targetVal: kr['targetVal'] as double,
                currentVal: kr['currentVal'] as double? ?? 0.0,
                unit: Value(kr['unit'] as String?),
                weight: Value(kr['weight'] as double? ?? 1.0),
              ),
            );
      }

      return insertedObj.id;
    });
  }

  /// 更新目标基本信息
  Future<void> updateObjective({
    required String id,
    String? title,
    String? description,
    int? deadline,
  }) async {
    await (_db.update(_db.objectives)..where((t) => t.id.equals(id))).write(
      ObjectivesCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        description: description != null
            ? Value(description)
            : const Value.absent(),
        deadline: deadline != null ? Value(deadline) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  /// 删除目标（级联删除关键结果）
  Future<void> deleteObjective(String id) async {
    await (_db.delete(_db.objectives)..where((t) => t.id.equals(id))).go();
  }

  /// 归档目标
  Future<void> archiveObjective(String id) async {
    await (_db.update(_db.objectives)..where((t) => t.id.equals(id))).write(
      const ObjectivesCompanion(
        status: Value('archived'),
        isSynced: Value(false),
      ),
    );
  }

  // --- Key Result Operations ---

  /// 获取某个 Objective 的所有 KeyResults
  Future<List<KeyResultModel>> _getKeyResultsForObjective(
    String objectiveId,
  ) async {
    final krs = await (_db.select(
      _db.keyResults,
    )..where((t) => t.objectiveId.equals(objectiveId))).get();

    return krs.map((kr) => _keyResultFromDb(kr)).toList();
  }

  /// 更新 KeyResult 的当前值（触发进度重算）
  Future<void> updateKeyResultValue({
    required String krId,
    required double newValue,
    String? comment,
    int? confidence,
  }) async {
    await _db.addCheckIn(
      krId: krId,
      newValue: newValue,
      comment: comment,
      confidence: confidence,
    );
  }

  /// 添加新的 KeyResult 到现有 Objective
  Future<void> addKeyResult({
    required String objectiveId,
    required String title,
    required double targetVal,
    String? unit,
    double startVal = 0.0,
    double weight = 1.0,
  }) async {
    await _db
        .into(_db.keyResults)
        .insert(
          KeyResultsCompanion.insert(
            objectiveId: objectiveId,
            title: title,
            targetVal: targetVal,
            startVal: Value(startVal),
            currentVal: startVal,
            unit: Value(unit),
            weight: Value(weight),
          ),
        );

    // 触发重算
    await _recalculateObjectiveProgress(objectiveId);
  }

  /// 删除 KeyResult
  Future<void> deleteKeyResult(String krId) async {
    // 先获取 objectiveId 用于重算
    final kr = await (_db.select(
      _db.keyResults,
    )..where((t) => t.id.equals(krId))).getSingleOrNull();

    if (kr == null) return;

    await (_db.delete(_db.keyResults)..where((t) => t.id.equals(krId))).go();

    // 触发重算
    await _recalculateObjectiveProgress(kr.objectiveId);
  }

  /// 内部方法：重新计算 Objective 的进度
  Future<void> _recalculateObjectiveProgress(String objectiveId) async {
    final krs = await (_db.select(
      _db.keyResults,
    )..where((t) => t.objectiveId.equals(objectiveId))).get();

    if (krs.isEmpty) return;

    double totalWeight = 0.0;
    double weightedProgressSum = 0.0;

    for (final kr in krs) {
      double span = kr.targetVal - kr.startVal;
      double progress = 0.0;

      if (span.abs() > 0.0001) {
        progress = (kr.currentVal - kr.startVal) / span;
      } else {
        progress = kr.currentVal >= kr.targetVal ? 1.0 : 0.0;
      }

      weightedProgressSum += progress * kr.weight;
      totalWeight += kr.weight;
    }

    final finalProgress = totalWeight == 0
        ? 0.0
        : (weightedProgressSum / totalWeight) * 100;

    await (_db.update(
      _db.objectives,
    )..where((t) => t.id.equals(objectiveId))).write(
      ObjectivesCompanion(
        calculatedProgress: Value(finalProgress),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  // --- Helper Methods ---

  ObjectiveModel _objectiveFromDb(Objective obj, List<KeyResultModel> krs) {
    return ObjectiveModel(
      id: obj.id,
      title: obj.title,
      description: obj.description,
      period: obj.period,
      deadline: obj.deadline,
      status: obj.status,
      calculatedProgress: obj.calculatedProgress,
      keyResults: krs,
      priority: 2, // TODO: Add to DB schema
      owner: null, // TODO: Add to DB schema
      createdAt: obj.createdAt,
    );
  }

  KeyResultModel _keyResultFromDb(KeyResult kr) {
    return KeyResultModel(
      id: kr.id,
      objectiveId: kr.objectiveId,
      title: kr.title,
      type: kr.type,
      startVal: kr.startVal,
      targetVal: kr.targetVal,
      currentVal: kr.currentVal,
      unit: kr.unit,
      weight: kr.weight,
    );
  }
}
