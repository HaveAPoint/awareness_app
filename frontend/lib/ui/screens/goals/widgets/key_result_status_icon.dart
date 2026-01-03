import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 三态 Key Result 状态图标
/// - State A (progress == 0): 灰色空心圆
/// - State B (0 < progress < 1): 微型圆形进度指示器
/// - State C (progress >= 1): 绿色完成勾选
class KeyResultStatusIcon extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final Color activeColor;
  final Color trackColor;
  final Color completedColor;

  const KeyResultStatusIcon({
    super.key,
    required this.progress,
    this.size = 18,
    this.activeColor = const Color(0xFF7C3AED), // Purple-600
    this.trackColor = const Color(0xFFE5E7EB), // Grey-200
    this.completedColor = const Color(0xFF10B981), // Emerald-500
  });

  @override
  Widget build(BuildContext context) {
    // State C: 完成
    if (progress >= 1.0) {
      return Icon(
        Icons.check_circle_rounded,
        size: size,
        color: completedColor,
      );
    }

    // State A: 空状态
    if (progress <= 0.0) {
      return Icon(
        Icons.circle_outlined,
        size: size,
        color: trackColor,
      );
    }

    // State B: 进行中 - 微型圆形进度
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MicroProgressPainter(
          progress: progress,
          activeColor: activeColor,
          trackColor: trackColor,
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}

/// 自定义微型圆形进度绘制器
class _MicroProgressPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  _MicroProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 轨道（背景圆环）
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 进度弧
    final progressPaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 从顶部开始
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MicroProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
