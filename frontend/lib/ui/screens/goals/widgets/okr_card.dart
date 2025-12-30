import 'package:flutter/material.dart';
import 'package:awareness_app/data/models/goal_models.dart';
import 'insight_progress_bar.dart';

class GoalCard extends StatelessWidget {
  final ObjectiveModel objective;

  const GoalCard({super.key, required this.objective});

  @override
  Widget build(BuildContext context) {
    // Calculate urgency (mock logic for demo)
    final daysLeft = objective.daysRemaining;
    final isUrgent = daysLeft < 14;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            // 1. Header: Title
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
                // Optional: Menu icon or status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getHealthColor(objective.healthStatus),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

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
              ...objective.keyResults
                  .take(3)
                  .map(
                    (kr) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          // Custom check circle
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: kr.progress >= 1.0
                                      ? Colors.blueAccent
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              kr.title,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "${(kr.progress * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
