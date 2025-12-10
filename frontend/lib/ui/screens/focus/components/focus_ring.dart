import 'package:flutter/material.dart';

class FocusRing extends StatefulWidget {
  final double progress;
  final bool isRunning;
  final VoidCallback onTap;

  const FocusRing({
    super.key,
    required this.progress,
    required this.isRunning,
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

    // 缩放幅度控制在 4% 以内，手感更紧实
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  // 外部控制：按下
  void pressDown() {
    _scaleController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 20),
      curve: Curves.easeOut,
    );
  }

  // 外部控制：抬起/回弹
  void pressUp({bool bounce = true}) {
    _scaleController.animateTo(
      0.0,
      duration: Duration(milliseconds: bounce ? 150 : 120),
      curve: bounce ? Curves.easeOutBack : Curves.easeOut,
    );
  }

  // 外部控制：取消
  void pressCancel() {
    pressUp(bounce: false);
  }

  @override
  Widget build(BuildContext context) {
    // 基础尺寸
    const double size = 300.0;
    const double strokeWidth = 18.0; // 加粗圆环

    // 颜色定义 (性冷淡风)
    final Color activeColor = widget.isRunning
        ? const Color(0xFF64FFDA) // 经典的 Cyan Accent
        : const Color(0xFFE0E0E0); // 停止时用高级灰

    final Color inactiveColor = Colors.white.withOpacity(0.05);
    final Color innerColorStart = const Color(0xFF202025); // 内芯渐变亮部
    final Color innerColorEnd = const Color(0xFF15151A); // 内芯渐变暗部

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
                // --- 1. 内部实体按钮 (微凸起效果) ---
                Container(
                  width: size - strokeWidth * 2 - 10, // 稍微留点缝隙，显得更精致
                  height: size - strokeWidth * 2 - 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // 哑光渐变：模拟微凸的曲面光感
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [innerColorStart, innerColorEnd],
                    ),
                    // 阴影：制造悬浮感 (Shadow)
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(4, 4),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        offset: const Offset(-2, -2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),

                // --- 2. 进度圆环 (CustomPaint 绘制，以获得最佳圆角) ---
                // 使用 RepaintBoundary 优化性能
                RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(size, size),
                    painter: _RingPainter(
                      progress: widget.progress,
                      strokeWidth: strokeWidth,
                      color: activeColor,
                      backgroundColor: inactiveColor,
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
  final Color color;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
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
    // 定义一个渐变笔刷，让进度条本身也有点金属质感
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap
          .round // 圆头
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withOpacity(0.7)], // 微微的渐变
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // -pi/2 是为了从12点钟方向开始
    // progress * 2 * pi 计算弧度
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      progress * 2 * 3.14159,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
