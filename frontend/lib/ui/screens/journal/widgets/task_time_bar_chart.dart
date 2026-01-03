import 'package:flutter/material.dart';

/// 任务时间数据
class TaskTimeData {
  final String taskId;
  final String taskTitle;
  final double effectiveMinutes;
  final Color color;

  const TaskTimeData({
    required this.taskId,
    required this.taskTitle,
    required this.effectiveMinutes,
    required this.color,
  });
}

/// 任务时间横向条形图
///
/// 使用相对缩放（Relative Scaling）：最长的条形作为100%上限
class TaskTimeBarChart extends StatelessWidget {
  final List<TaskTimeData> tasks;
  final String? title;

  const TaskTimeBarChart({
    super.key,
    required this.tasks,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    // 相对缩放：找到最大值作为上限
    final maxMinutes = tasks.map((t) => t.effectiveMinutes).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...tasks.map((task) => _TaskTimeBar(
              task: task,
              maxMinutes: maxMinutes,
            )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 40,
              color: Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              '今日暂无任务记录',
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
}

/// 单个任务的时间条
class _TaskTimeBar extends StatelessWidget {
  final TaskTimeData task;
  final double maxMinutes;

  const _TaskTimeBar({
    required this.task,
    required this.maxMinutes,
  });

  @override
  Widget build(BuildContext context) {
    // 计算相对进度 (0.0 - 1.0)
    final progress = maxMinutes > 0 ? (task.effectiveMinutes / maxMinutes).clamp(0.0, 1.0) : 0.0;

    // 格式化时间
    final mins = task.effectiveMinutes.toInt();
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;
    final timeText = hours > 0 ? '${hours}h ${remainingMins}m' : '${remainingMins}m';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 任务名称 + 时间
          Row(
            children: [
              // 颜色指示器
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: task.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              // 任务名称
              Expanded(
                child: Text(
                  task.taskTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 时间
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: task.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 横向进度条
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // 背景轨道
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // 进度条（带动画）
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Container(
                        height: 12,
                        width: constraints.maxWidth * value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              task.color,
                              task.color.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: task.color.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
