import 'package:flutter/material.dart';
import 'package:awareness_app/data/models/goal_models.dart';
import 'insight_progress_bar.dart';
import 'key_result_row.dart';

class GoalCard extends StatelessWidget {
  final ObjectiveModel objective;
  final void Function(KeyResultModel kr)? onStartFocusForKr;
  final void Function(KeyResultModel kr)? onEditKr;
  final void Function(KeyResultModel kr)? onCompleteKr;
  final void Function(KeyResultModel kr)? onUncompleteKr; // 新增：取消完成回调
  final VoidCallback? onEdit; // 新增：整个目标的编辑回调

  const GoalCard({
    super.key,
    required this.objective,
    this.onStartFocusForKr,
    this.onEditKr,
    this.onCompleteKr,
    this.onUncompleteKr,
    this.onEdit, // 新增
  });

  @override
  Widget build(BuildContext context) {
    // Calculate urgency (mock logic for demo)
    final daysLeft = objective.daysRemaining;
    final isUrgent = daysLeft < 14;

    return InkWell(
      onTap: onEdit, // 整个卡片可点击
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Title + Edit Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      objective.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // 编辑图标（替换原来的健康状态点）
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),

              // 描述（如有）
              if (objective.description != null && objective.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  objective.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 24),

              // 2. Ghost Progress Bar
              // Label row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Progress",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "${(objective.totalProgress * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // The Bar
              InsightProgressBar(
                timeElapsed: objective.timeElapsedPercent,
                actualProgress: objective.totalProgress,
                healthStatus: objective.healthStatus,
                height: 12,
                borderRadius: 6,
              ),

              const SizedBox(height: 24),

              // 3. Key Results List
              if (objective.keyResults.isNotEmpty) ...[
                ...objective.keyResults.take(3).map(
                      (kr) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: KeyResultRow(
                          keyResult: kr,
                          accentColor: Colors.blueAccent,
                          onStartFocus: onStartFocusForKr != null
                              ? () => onStartFocusForKr!(kr)
                              : null,
                          onEdit: onEditKr != null ? () => onEditKr!(kr) : null,
                          onComplete: onCompleteKr != null
                              ? () => onCompleteKr!(kr)
                              : null,
                          onUncomplete: onUncompleteKr != null
                              ? () => onUncompleteKr!(kr)
                              : null,
                        ),
                      ),
                    ),
              ],

              const SizedBox(height: 12),
              Divider(color: Colors.grey[100], height: 1),
              const SizedBox(height: 16),

              // 4. Footer
              Row(
                children: [
                  // Avatar group (mock)
                  SizedBox(
                    height: 32,
                    width: 60,
                    child: Stack(
                      children: [
                        _buildAvatar(
                          objective.owner ?? "U",
                          Colors.blue[100]!,
                          0,
                        ),
                        // Mock second user for "team" feel
                        Positioned(
                          left: 20,
                          child: _buildAvatar("M", Colors.purple[100]!, 1),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Urgency Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? const Color(0xFFFFF8E1)
                          : const Color(0xFFE3F2FD), // Amber-50 vs Blue-50
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isUrgent
                              ? const Color(0xFFFFA000)
                              : Colors.blue, // Amber-700
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$daysLeft days left",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isUrgent
                                ? const Color(0xFFFFA000)
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial, Color color, int index) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          initial.substring(0, 1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Color _getHealthColor(String status) {
    switch (status) {
      case 'healthy':
        return const Color(0xFF00C853); // Green
      case 'at-risk':
        return const Color(0xFFFFAB00); // Amber
      case 'off-track':
        return const Color(0xFFFF3D00); // Red
      default:
        return Colors.grey;
    }
  }
}
