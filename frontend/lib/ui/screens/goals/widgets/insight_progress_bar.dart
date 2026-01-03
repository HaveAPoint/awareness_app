import 'package:flutter/material.dart';

/// InsightProgressBar - Dual Progress Bar (Non-overlapping)
/// Shows time elapsed and actual completion side by side.
/// The bar that progresses faster is rendered brighter.
/// The bar that progresses slower is rendered darker.
class InsightProgressBar extends StatelessWidget {
  final double timeElapsed; // 0.0 - 1.0
  final double actualProgress; // 0.0 - 1.0
  final String healthStatus; // 'healthy', 'at-risk', 'off-track'
  final double height;
  final double borderRadius;

  const InsightProgressBar({
    super.key,
    required this.timeElapsed,
    required this.actualProgress,
    required this.healthStatus,
    this.height = 8.0,
    this.borderRadius = 4.0,
  });

  Color get _baseProgressColor {
    switch (healthStatus) {
      case 'healthy':
        return const Color(0xFF00C853); // Green
      case 'at-risk':
        return const Color(0xFFFFAB00); // Amber
      case 'off-track':
        return const Color(0xFFFF3D00); // Red
      default:
        return Colors.blue;
    }
  }

  /// Opacity for actual progress: 1.0 (bright) if faster, 0.5 (dark) if slower
  double get _actualOpacity => actualProgress >= timeElapsed ? 1.0 : 0.5;

  /// Opacity for time progress: 1.0 (bright) if faster, 0.5 (dark) if slower
  double get _timeOpacity => timeElapsed >= actualProgress ? 1.0 : 0.5;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time Progress Bar
        _buildProgressRow(
          label: 'Time',
          value: timeElapsed,
          color: Colors.blueGrey[300]!,
          opacity: _timeOpacity,
        ),
        const SizedBox(height: 8),

        // Work Progress Bar
        _buildProgressRow(
          label: 'Progress',
          value: actualProgress,
          color: _baseProgressColor,
          opacity: _actualOpacity,
        ),
      ],
    );
  }

  Widget _buildProgressRow({
    required String label,
    required double value,
    required Color color,
    required double opacity,
  }) {
    return Row(
      children: [
        // Label (minimal width for alignment)
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Progress Bar
        Expanded(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color.withValues(alpha: opacity),
                ),
                minHeight: height,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Percentage Text
        SizedBox(
          width: 32,
          child: Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
