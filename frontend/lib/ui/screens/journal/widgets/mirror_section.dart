import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../main.dart'; // for db
import '../../../../data/database/database.dart';
import 'chronos_dial.dart';
import 'weighted_objective_tile.dart';

/// Mirror Section - 觉知仪表盘
///
/// 整合 ChronosDial 和 WeightedObjectiveTile，
/// 提供今日时间分配和目标进度的可视化
class MirrorSection extends StatelessWidget {
  const MirrorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '觉知镜像',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 主体内容
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 1. ChronosDial - 时间分配圆盘
                  _buildChronosDialSection(context),
                  const SizedBox(height: 32),

                  // 2. WeightedObjectiveTile 列表
                  _buildObjectivesSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 ChronosDial 区域
  Widget _buildChronosDialSection(BuildContext context) {
    return StreamBuilder<List<_SessionWithObjective>>(
      stream: _getTodaySessionsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final sessionsWithObjectives = snapshot.data!;

        // 转换为 PomodoroSessionData 格式
        final sessions = sessionsWithObjectives.map((item) {
          final color = _getColorForObjective(item.objectiveId);
          return PomodoroSessionData.fromFocusSession(item.session, color);
        }).toList();

        return Column(
          children: [
            ChronosDial(
              sessions: sessions,
              size: 240,
            ),
            const SizedBox(height: 12),
            Text(
              '已完成 ${sessions.length} 个番茄钟',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建目标进度列表
  Widget _buildObjectivesSection(BuildContext context) {
    return StreamBuilder<List<_ObjectiveWithSessions>>(
      stream: _getObjectivesWithSessionsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final objectivesWithSessions = snapshot.data!;

        if (objectivesWithSessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 48,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '暂无活跃目标',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 20),
            Text(
              '目标进度（基于有效时间）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...objectivesWithSessions.map((item) {
              // 计算有效时间
              final effectiveMinutes =
                  calculateEffectiveMinutes(item.sessions);

              // 默认目标：120分钟有效时间 (2小时高质量工作)
              final targetMinutes = 120;

              return WeightedObjectiveTile(
                objective: item.objective,
                targetEffectiveMinutes: targetMinutes,
                currentEffectiveMinutes: effectiveMinutes,
                color: _getColorForObjective(item.objective.id),
              );
            }),
          ],
        );
      },
    );
  }

  /// 获取今天的所有会话（带目标信息）
  Stream<List<_SessionWithObjective>> _getTodaySessionsStream() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final startTimestamp = todayStart.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = todayEnd.millisecondsSinceEpoch ~/ 1000;

    final query = db.select(db.focusSessions)
      ..where((t) =>
          t.startTime.isBiggerOrEqualValue(startTimestamp) &
          t.startTime.isSmallerThanValue(endTimestamp))
      ..orderBy([(t) => drift.OrderingTerm.asc(t.startTime)]);

    return query.watch().asyncMap((sessions) async {
      final result = <_SessionWithObjective>[];

      for (final session in sessions) {
        String? objectiveId;

        if (session.taskId != null) {
          final task = await (db.select(db.tasks)
                ..where((t) => t.id.equals(session.taskId!)))
              .getSingleOrNull();

          if (task?.krId != null) {
            final kr = await (db.select(db.keyResults)
                  ..where((t) => t.id.equals(task!.krId!)))
                .getSingleOrNull();

            objectiveId = kr?.objectiveId;
          }
        }

        result.add(_SessionWithObjective(
          session: session,
          objectiveId: objectiveId ?? 'unknown',
        ));
      }

      return result;
    });
  }

  /// 获取活跃目标及其今天的会话
  Stream<List<_ObjectiveWithSessions>> _getObjectivesWithSessionsStream() {
    final objectivesQuery = db.select(db.objectives)
      ..where((t) => t.status.equals('active'))
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.createdAt,
              mode: drift.OrderingMode.desc,
            ),
      ]);

    return objectivesQuery.watch().asyncMap((objectives) async {
      final result = <_ObjectiveWithSessions>[];

      for (final objective in objectives) {
        final sessions = await _getSessionsForObjective(objective.id);
        result.add(_ObjectiveWithSessions(
          objective: objective,
          sessions: sessions,
        ));
      }

      return result;
    });
  }

  /// 获取某个目标今天的所有会话
  Future<List<FocusSession>> _getSessionsForObjective(
      String objectiveId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final startTimestamp = todayStart.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = todayEnd.millisecondsSinceEpoch ~/ 1000;

    final krs = await (db.select(db.keyResults)
          ..where((t) => t.objectiveId.equals(objectiveId)))
        .get();

    final krIds = krs.map((kr) => kr.id).toList();
    if (krIds.isEmpty) return [];

    final tasks = await (db.select(db.tasks)
          ..where((t) => t.krId.isIn(krIds)))
        .get();

    final taskIds = tasks.map((task) => task.id).toList();
    if (taskIds.isEmpty) return [];

    final sessions = await (db.select(db.focusSessions)
          ..where((t) =>
              t.taskId.isIn(taskIds) &
              t.startTime.isBiggerOrEqualValue(startTimestamp) &
              t.startTime.isSmallerThanValue(endTimestamp)))
        .get();

    return sessions;
  }

  /// 根据目标ID获取颜色
  Color _getColorForObjective(String objectiveId) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];

    final index = objectiveId.hashCode.abs() % colors.length;
    return colors[index];
  }
}

/// 辅助类：会话 + 目标ID
class _SessionWithObjective {
  final FocusSession session;
  final String objectiveId;

  _SessionWithObjective({
    required this.session,
    required this.objectiveId,
  });
}

/// 辅助类：目标 + 会话列表
class _ObjectiveWithSessions {
  final Objective objective;
  final List<FocusSession> sessions;

  _ObjectiveWithSessions({
    required this.objective,
    required this.sessions,
  });
}
