import 'package:flutter/material.dart';
import '../../../../data/database/database.dart';

/// 基于效率加权的目标进度卡片
///
/// 逻辑：
/// - currentEffectiveMinutes = Sum(session.duration * session.efficiencyScore)
/// - progress = currentEffectiveMinutes / targetEffectiveMinutes
///
/// 强调质量高于数量：低效率时间（如 efficiencyScore=0.1）对进度贡献极小
class WeightedObjectiveTile extends StatelessWidget {
  final Objective objective;
  final int targetEffectiveMinutes; // 目标的有效时间（分钟）
  final double currentEffectiveMinutes; // 当前有效时间（基于效率加权）
  final Color? color; // 可选的主题色

  const WeightedObjectiveTile({
    super.key,
    required this.objective,
    required this.targetEffectiveMinutes,
    required this.currentEffectiveMinutes,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeColor = color ?? colorScheme.primary;

    // 计算进度 (0.0 - 1.0)
    final progress = targetEffectiveMinutes > 0
        ? (currentEffectiveMinutes / targetEffectiveMinutes).clamp(0.0, 1.0)
        : 0.0;

    // 格式化时间显示
    final currentMins = currentEffectiveMinutes.toInt();
    final currentHours = currentMins ~/ 60;
    final currentRemainingMins = currentMins % 60;

    final targetHours = targetEffectiveMinutes ~/ 60;
    final targetRemainingMins = targetEffectiveMinutes % 60;

    final currentTimeText = currentHours > 0
        ? '${currentHours}h ${currentRemainingMins}m'
        : '${currentRemainingMins}m';

    final targetTimeText = targetHours > 0
        ? '${targetHours}h ${targetRemainingMins}m'
        : '${targetRemainingMins}m';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目标标题
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  objective.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: themeColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),

          // 有效时间标签
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '有效时间',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentTimeText / $targetTimeText',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 辅助函数：从 FocusSession 计算有效时间
///
/// 将 focusQuality (1-5星) 映射到 efficiencyScore (0.0-1.0)
/// effectiveMinutes = duration * (focusQuality / 5.0)
double calculateEffectiveMinutes(List<FocusSession> sessions) {
  return sessions.fold(0.0, (sum, session) {
    // 将 focusQuality (1-5) 转换为 efficiencyScore (0.0-1.0)
    final quality = session.focusQuality ?? 3; // 默认3星 (0.6效率)
    final efficiencyScore = (quality / 5.0).clamp(0.0, 1.0);

    // 计算有效时间（分钟）
    final durationMinutes = session.durationSeconds / 60.0;
    final effectiveMinutes = durationMinutes * efficiencyScore;

    return sum + effectiveMinutes;
  });
}
