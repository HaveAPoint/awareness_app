import 'package:flutter/material.dart';

class FocusRing extends StatefulWidget {
  final double progress;
  final bool isRunning;
  final bool isResting; // 新增：用于判断是否显示暖色渐变
  final VoidCallback onTap;

  const FocusRing({
    super.key,
    required this.progress,
    required this.isRunning,
    required this.isResting, // 传入此参数
    required this.onTap,
  });

  @override
  State<FocusRing> createState() => FocusRingState();
}

class FocusRingState extends State<FocusRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void pressDown() {
    _scaleController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 20),
      curve: Curves.easeOut,
    );
  }

  void pressUp({bool bounce = true}) {
    _scaleController.animateTo(
      0.0,
      duration: Duration(milliseconds: bounce ? 150 : 120),
      curve: bounce ? Curves.easeOutBack : Curves.easeOut,
    );
  }

  void pressCancel() {
    pressUp(bounce: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 基础尺寸保持不变
    const double size = 300.0;
    const double strokeWidth = 18.0;

    // 内芯颜色
    final Color innerColorStart = colorScheme.surfaceContainerHigh;
    final Color innerColorEnd = colorScheme.surfaceContainer;
    // 轨道底色
    final Color inactiveColor = colorScheme.outlineVariant.withOpacity(0.2);

    // 动态生成渐变
    final Gradient restGradient = SweepGradient(
      colors: [
        colorScheme.tertiaryContainer,
        colorScheme.tertiary,
        colorScheme.tertiaryContainer,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final Gradient workGradient = SweepGradient(
      colors: [
        colorScheme.primaryContainer,
        colorScheme.primary,
        colorScheme.primaryContainer,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final Color idleColor = colorScheme.outline;

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // --- 1. 内部实体按钮 ---
                Container(
                  width: size - strokeWidth * 2 - 10,
                  height: size - strokeWidth * 2 - 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [innerColorStart, innerColorEnd],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        offset: const Offset(4, 4),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: colorScheme.surface.withOpacity(0.5),
                        offset: const Offset(-2, -2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),

                // --- 2. 进度圆环 (使用 CustomPaint 支持 SweepGradient) ---
                RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(size, size),
                    painter: _RingPainter(
                      progress: widget.progress.clamp(0.0, 1.0),
                      strokeWidth: strokeWidth,
                      backgroundColor: inactiveColor,
                      // 颜色逻辑：如果正在运行且是休息状态 -> 使用暖色渐变，否则使用单色
                      useWarmGradient: widget.isRunning && widget.isResting,
                      warmGradient: restGradient,
                      workGradient: workGradient,
                      idleColor: idleColor,
                      isRunning: widget.isRunning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final bool useWarmGradient;
  final Gradient warmGradient;
  final Gradient workGradient;
  final Color idleColor;
  final bool isRunning;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.useWarmGradient,
    required this.warmGradient,
    required this.workGradient,
    required this.idleColor,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. 画背景轨道
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // 2. 画进度
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // 如果使用暖色渐变（休息状态）
      if (useWarmGradient) {
        progressPaint.shader = warmGradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );
      } else if (isRunning) {
        // 工作态使用深海专注渐变
        progressPaint.shader = workGradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );
      } else {
        // 空闲态使用单色
        progressPaint.color = idleColor;
      }

      // 从12点钟方向开始绘制
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2, // -90度，从12点开始
        progress * 2 * 3.14159, // 根据进度计算弧度
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.useWarmGradient != useWarmGradient ||
        oldDelegate.isRunning != isRunning;
  }
}
