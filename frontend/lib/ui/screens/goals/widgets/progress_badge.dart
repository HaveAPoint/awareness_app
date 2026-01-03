import 'package:flutter/material.dart';

/// 精致的椭圆形进度徽章
/// 显示百分比数值，使用素色椭圆背景
class ProgressBadge extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double fontSize;
  final EdgeInsets padding;

  const ProgressBadge({
    super.key,
    required this.progress,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();

    // 根据进度选择不同的素色
    final (bgColor, textColor) = _getColors(progress);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }

  /// 根据进度返回背景色和文字色
  (Color, Color) _getColors(double progress) {
    if (progress >= 1.0) {
      // 完成：柔和的绿色
      return (
        const Color(0xFFD1FAE5), // Emerald-100
        const Color(0xFF059669), // Emerald-600
      );
    } else if (progress >= 0.7) {
      // 高进度：柔和的蓝色
      return (
        const Color(0xFFDBEAFE), // Blue-100
        const Color(0xFF2563EB), // Blue-600
      );
    } else if (progress >= 0.3) {
      // 中等进度：柔和的琥珀色
      return (
        const Color(0xFFFEF3C7), // Amber-100
        const Color(0xFFD97706), // Amber-600
      );
    } else if (progress > 0) {
      // 低进度：柔和的石板灰
      return (
        const Color(0xFFF1F5F9), // Slate-100
        const Color(0xFF64748B), // Slate-500
      );
    } else {
      // 零进度：更淡的灰色
      return (
        const Color(0xFFF8FAFC), // Slate-50
        const Color(0xFF94A3B8), // Slate-400
      );
    }
  }
}
