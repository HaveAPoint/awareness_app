// 目标相关的视图模型
// 基于数据库表 Objectives 和 KeyResults

class KeyResultModel {
  final String id;
  final String objectiveId;
  final String title;
  final String type; // 'number', 'boolean', 'percent', 'currency'
  final double startVal;
  final double targetVal;
  final double currentVal;
  final String? unit;
  final double weight;

  // 计算属性：进度百分比 (0.0 - 1.0)
  double get progress {
    if (targetVal == 0) return 0.0;
    return ((currentVal - startVal) / (targetVal - startVal)).clamp(0.0, 1.0);
  }

  const KeyResultModel({
    required this.id,
    required this.objectiveId,
    required this.title,
    required this.type,
    required this.startVal,
    required this.targetVal,
    required this.currentVal,
    this.unit,
    this.weight = 1.0,
  });

  // 从数据库记录创建
  factory KeyResultModel.fromDb(Map<String, dynamic> row) {
    return KeyResultModel(
      id: row['id'] as String,
      objectiveId: row['objectiveId'] as String,
      title: row['title'] as String,
      type: row['type'] as String? ?? 'number',
      startVal: (row['startVal'] as num?)?.toDouble() ?? 0.0,
      targetVal: (row['targetVal'] as num).toDouble(),
      currentVal: (row['currentVal'] as num).toDouble(),
      unit: row['unit'] as String?,
      weight: (row['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class ObjectiveModel {
  final String id;
  final String title;
  final String? description;
  final String? period; // e.g., "2024-Q1", "2024-Week-12"
  final int deadline; // UNIX timestamp
  final String status; // 'active', 'completed', 'archived'
  final double calculatedProgress;
  final List<KeyResultModel> keyResults;

  // New fields for enhanced UI
  final int priority; // 0 (P0/Highest) to 3 (P3/Lowest)
  final String? owner; // Owner name or avatar identifier
  final DateTime createdAt; // For calculating time elapsed

  // Health status based on progress vs time
  String get healthStatus {
    final timeElapsed = _calculateTimeElapsed();
    if (calculatedProgress >= timeElapsed - 0.1) return 'healthy'; // Green
    if (calculatedProgress >= timeElapsed - 0.25) return 'at-risk'; // Amber
    return 'off-track'; // Red
  }

  // Calculate time elapsed as percentage (0.0 - 1.0)
  double _calculateTimeElapsed() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final start = createdAt.millisecondsSinceEpoch ~/ 1000;
    final end = deadline;

    if (end <= start) return 1.0;
    final elapsed = (now - start) / (end - start);
    return elapsed.clamp(0.0, 1.0);
  }

  double get timeElapsedPercent => _calculateTimeElapsed();

  int get daysRemaining {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = deadline - now;
    return (remaining / 86400).ceil().clamp(0, 9999);
  }

  // 计算属性：目标的总进度是所有 KR 加权平均
  double get totalProgress {
    if (keyResults.isEmpty) return calculatedProgress;

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (final kr in keyResults) {
      weightedSum += kr.progress * kr.weight;
      totalWeight += kr.weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  ObjectiveModel({
    required this.id,
    required this.title,
    this.description,
    this.period,
    required this.deadline,
    this.status = 'active',
    this.calculatedProgress = 0.0,
    this.keyResults = const [],
    this.priority = 2, // Default to P2 (Medium)
    this.owner,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // 从数据库记录创建
  factory ObjectiveModel.fromDb(
    Map<String, dynamic> row, {
    List<KeyResultModel>? keyResults,
  }) {
    return ObjectiveModel(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      period: row['period'] as String?,
      deadline: row['deadline'] as int,
      status: row['status'] as String? ?? 'active',
      calculatedProgress:
          (row['calculatedProgress'] as num?)?.toDouble() ?? 0.0,
      keyResults: keyResults ?? [],
      priority: 2, // TODO: Add priority to database
      owner: null, // TODO: Add owner to database
      createdAt: row['createdAt'] != null
          ? DateTime.parse(row['createdAt'] as String)
          : DateTime.now(),
    );
  }

  // 复制并更新 keyResults
  ObjectiveModel copyWith({
    List<KeyResultModel>? keyResults,
    int? priority,
    String? owner,
  }) {
    return ObjectiveModel(
      id: id,
      title: title,
      description: description,
      period: period,
      deadline: deadline,
      status: status,
      calculatedProgress: calculatedProgress,
      keyResults: keyResults ?? this.keyResults,
      priority: priority ?? this.priority,
      owner: owner ?? this.owner,
      createdAt: createdAt,
    );
  }
}
