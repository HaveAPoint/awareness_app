import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/goal_models.dart';

/// OKR 仓储层 - 负责 Objectives 和 KeyResults 的数据持久化
class GoalRepository {
  final AppDatabase _db;

  GoalRepository(this._db);

  // --- Objective CRUD ---

  /// 获取目标列表
  /// [statusFilter] 状态筛选：'all', 'active', 'completed', 'archived'
  Future<List<ObjectiveModel>> getAllObjectives({
    String statusFilter = 'active',
  }) async {
    // 先自动检查并更新过期目标
    await _db.autoCompleteExpiredObjectives();

    var query = _db.select(_db.objectives);

    // 根据筛选条件添加 where 子句
    if (statusFilter == 'all') {
      // 全部 = active + completed（排除archived）
      query = query..where((t) => t.status.isNotValue('archived'));
    } else {
      // 精确匹配状态
      query = query..where((t) => t.status.equals(statusFilter));
    }

    final objectives =
        await (query..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

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

  /// 更新 Objective 及其所有 KeyResults（事务处理）
  /// 用于编辑目标时同时更新基本信息和KR列表
  Future<void> updateObjectiveWithKeyResults({
    required String objectiveId,
    required String title,
    String? description,
    required int deadline,
    required List<Map<String, dynamic>> keyResults,
  }) async {
    await _db.transaction(() async {
      // 1. 更新 Objective 基本信息
      await updateObjective(
        id: objectiveId,
        title: title,
        description: description,
        deadline: deadline,
      );

      // 2. 获取现有 KRs
      final existingKrs = await _getKeyResultsForObjective(objectiveId);
      final existingKrMap = {for (var kr in existingKrs) kr.id: kr};

      // 3. 处理传入的 KRs
      final updatedKrIds = <String>{};

      for (final krData in keyResults) {
        final krId = krData['id'] as String?;

        if (krId != null && existingKrMap.containsKey(krId)) {
          // 更新现有 KR（保留 currentVal）
          await updateKeyResult(
            krId: krId,
            title: krData['title'] as String,
            targetVal: krData['target'] as double,
            unit: krData['unit'] as String?,
            weight: krData['weight'] as double?,
          );
          updatedKrIds.add(krId);
        } else {
          // 添加新 KR
          await addKeyResult(
            objectiveId: objectiveId,
            title: krData['title'] as String,
            targetVal: krData['target'] as double,
            unit: krData['unit'] as String?,
            weight: krData['weight'] as double? ?? 1.0,
          );
        }
      }

      // 4. 删除被移除的 KRs
      for (final existingKr in existingKrs) {
        if (!updatedKrIds.contains(existingKr.id)) {
          await deleteKeyResult(existingKr.id);
        }
      }

      // 5. 最终重算进度（各方法内已触发，但为保险再执行一次）
      await _recalculateObjectiveProgress(objectiveId);
    });
  }

  // --- Key Result Operations ---

  /// 获取某个 Objective 的所有 KeyResults（包含番茄钟时间）
  Future<List<KeyResultModel>> _getKeyResultsForObjective(
    String objectiveId,
  ) async {
    final krs = await (_db.select(
      _db.keyResults,
    )..where((t) => t.objectiveId.equals(objectiveId))).get();

    // 查询每个 KR 的实际番茄钟时间
    final result = <KeyResultModel>[];
    for (final kr in krs) {
      final actualHours = await _db.getKrActualHours(kr.id);
      result.add(_keyResultFromDb(kr, actualHours: actualHours));
    }
    return result;
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

  /// 更新 KeyResult 的元数据（title, targetVal, unit, weight）
  /// 注意：不修改 currentVal，进度值仅通过 addCheckIn 更新
  Future<void> updateKeyResult({
    required String krId,
    String? title,
    double? targetVal,
    String? unit,
    double? weight,
  }) async {
    // 先获取 objectiveId 用于重算
    final kr = await (_db.select(
      _db.keyResults,
    )..where((t) => t.id.equals(krId))).getSingleOrNull();

    if (kr == null) return;

    await (_db.update(_db.keyResults)..where((t) => t.id.equals(krId))).write(
      KeyResultsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        targetVal: targetVal != null ? Value(targetVal) : const Value.absent(),
        unit: unit != null ? Value(unit) : const Value.absent(),
        weight: weight != null ? Value(weight) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );

    // 触发重算
    await _recalculateObjectiveProgress(kr.objectiveId);
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

  KeyResultModel _keyResultFromDb(KeyResult kr, {double actualHours = 0.0}) {
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
      actualHours: actualHours,
    );
  }

  /// 将 KeyResult 标记为完成（currentVal = targetVal）
  Future<void> completeKeyResult(String krId) async {
    // 获取 KR 信息
    final kr = await (_db.select(
      _db.keyResults,
    )..where((t) => t.id.equals(krId))).getSingleOrNull();

    if (kr == null) return;

    // 设置 currentVal = targetVal
    await (_db.update(_db.keyResults)..where((t) => t.id.equals(krId))).write(
      KeyResultsCompanion(
        currentVal: Value(kr.targetVal),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );

    // 重算 Objective 进度
    await _recalculateObjectiveProgress(kr.objectiveId);
  }

  /// 取消 KeyResult 的完成状态（currentVal = 0，恢复为未完成）
  Future<void> uncompleteKeyResult(String krId) async {
    // 获取 KR 信息
    final kr = await (_db.select(
      _db.keyResults,
    )..where((t) => t.id.equals(krId))).getSingleOrNull();

    if (kr == null) return;

    // 设置 currentVal = startVal (恢复初始值)
    await (_db.update(_db.keyResults)..where((t) => t.id.equals(krId))).write(
      KeyResultsCompanion(
        currentVal: Value(kr.startVal),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );

    // 重算 Objective 进度
    await _recalculateObjectiveProgress(kr.objectiveId);
  }
}
