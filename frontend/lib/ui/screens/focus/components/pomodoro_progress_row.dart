import 'package:flutter/material.dart';

// 定义阶段类型
enum PomodoroStage {
  work, // 工作
  shortRest, // 短休息
  longRest, // 长休息
}

class PomodoroProgressRow extends StatelessWidget {
  // 当前进行到第几个阶段 (0 - 7)
  // 0=工作, 1=短休, 2=工作, 3=短休, 4=工作, 5=短休, 6=工作, 7=长休
  final int currentStepIndex;
  final bool enableTap;
  final void Function(PomodoroStage stage, int index)? onStageTap;

  const PomodoroProgressRow({
    super.key,
    required this.currentStepIndex,
    this.enableTap = false,
    this.onStageTap,
  });

  // 定义标准的番茄钟一轮循环：4个工作，3个短休，1个长休
  static const List<PomodoroStage> _cycleStructure = [
    PomodoroStage.work, // 1
    PomodoroStage.shortRest, // 1
    PomodoroStage.work, // 2
    PomodoroStage.shortRest, // 2
    PomodoroStage.work, // 3
    PomodoroStage.shortRest, // 3
    PomodoroStage.work, // 4
    PomodoroStage.longRest, // 4 (End)
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 两端对齐，中间自动间隔
        children: List.generate(_cycleStructure.length, (index) {
          final stage = _cycleStructure[index];
          final bool isActive = index == currentStepIndex;
          final bool isPast = index < currentStepIndex;
          return _buildIcon(context, stage, isActive, isPast, index);
        }),
      ),
    );
  }

  Widget _buildIcon(
    BuildContext context,
    PomodoroStage stage,
    bool isActive,
    bool isPast,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData iconData;
    switch (stage) {
      case PomodoroStage.work:
        iconData = Icons.menu_book_rounded; // 书本
        break;
      case PomodoroStage.shortRest:
        iconData = Icons.local_cafe_rounded; // 茶杯
        break;
      case PomodoroStage.longRest:
        iconData = Icons.directions_walk_rounded; // 步行
        break;
    }

    // --- 颜色与尺寸逻辑 ---
    // 激活状态：Primary
    // 过去状态：Secondary/Tertiary
    // 未来状态：Outline

    final Color color = isActive
        ? colorScheme.primary
        : (isPast ? colorScheme.secondary : colorScheme.outlineVariant);
    final double size = isActive ? 32.0 : 20.0; // 激活时变大，形成视觉焦点

    final iconWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack, // 稍微有点回弹效果
      child: Icon(iconData, color: color, size: size),
    );

    if (!enableTap) return iconWidget;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onStageTap?.call(stage, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: iconWidget,
      ),
    );
  }
}
