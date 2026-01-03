import 'package:flutter/material.dart';

/// 点前缀标签组件 - 极简主义设计
///
/// 使用小圆点作为视觉前缀，配合简洁文本，实现轻量级的分类标识
class DotLabel extends StatelessWidget {
  /// 圆点颜色
  final Color dotColor;

  /// 标签文本
  final String text;

  /// 文本颜色（可选，默认为灰色）
  final Color? textColor;

  /// 圆点大小（可选，默认为 6.0）
  final double dotSize;

  /// 圆点与文本间距（可选，默认为 6.0）
  final double spacing;

  /// 文本字号（可选，默认为 12.0）
  final double fontSize;

  /// 文本字重（可选，默认为 w500）
  final FontWeight fontWeight;

  const DotLabel({
    super.key,
    required this.dotColor,
    required this.text,
    this.textColor,
    this.dotSize = 6.0,
    this.spacing = 6.0,
    this.fontSize = 12.0,
    this.fontWeight = FontWeight.w500,
  });

  /// 工厂构造函数：Objective 标签
  ///
  /// 使用主题色圆点，默认文本为 "OBJ"
  factory DotLabel.objective(
    BuildContext context, {
    String? text,
    Color? dotColor,
    Color? textColor,
  }) {
    return DotLabel(
      dotColor: dotColor ?? Theme.of(context).colorScheme.primary,
      text: text ?? 'OBJ',
      textColor: textColor ?? Colors.grey[700],
    );
  }

  /// 工厂构造函数：Key Result 标签
  ///
  /// 使用次要颜色圆点，默认文本为 "KR"
  factory DotLabel.keyResult(
    BuildContext context, {
    String? text,
    Color? dotColor,
    Color? textColor,
  }) {
    return DotLabel(
      dotColor: dotColor ?? Colors.blueGrey,
      text: text ?? 'KR',
      textColor: textColor ?? Colors.grey[700],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 圆点
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),

        SizedBox(width: spacing),

        // 文本
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor ?? Colors.grey[700],
            height: 1.0, // 确保文本与圆点垂直对齐
          ),
        ),
      ],
    );
  }
}
