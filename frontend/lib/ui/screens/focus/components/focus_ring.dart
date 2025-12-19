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

  // --- 定义颜色常量 ---
  // 1. 秋日阳光渐变 (休息中)
  static const Gradient kAutumnSunGradient = SweepGradient(
    colors: [
      Color(0xFFFFD54F), // 明亮金
      Color(0xFFFF8F00), // 醇厚琥珀
      Color(0xFFBF360C), // 焦糖红棕
      Color(0xFFFFD54F), // 闭环
    ],
    stops: [0.0, 0.4, 0.8, 1.0],
  );

  // 2. 深海专注渐变 (工作中)
  static const Gradient kDeepFocusGradient = SweepGradient(
    colors: [
      Color(0xFF26C6DA), // 明亮青绿
      Color(0xFF0277BD), // 深邃海蓝
      Color(0xFF01579B), // 静谧午夜蓝
      Color(0xFF26C6DA), // 闭环
    ],
    stops: [0.0, 0.4, 0.8, 1.0],
  );

  // 3. 高级灰 (停止/空闲)
  static const Color kIdleColor = Color(0xFFE0E0E0);
  // ------------------

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
    // 基础尺寸保持不变
    const double size = 300.0;
    const double strokeWidth = 18.0;

    // 内芯颜色 (保持不变)
    final Color innerColorStart = const Color(0xFF202025);
    final Color innerColorEnd = const Color(0xFF15151A);
    // 轨道底色 (保持不变)
    final Color inactiveColor = Colors.white.withValues(alpha: 0.05);

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
                // --- 1. 内部实体按钮 (完全保持原样) ---
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
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(4, 4),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.05),
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
                      warmGradient: kAutumnSunGradient,
                      workGradient: kDeepFocusGradient,
                      idleColor: kIdleColor,
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
