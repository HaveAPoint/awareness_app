import 'dart:math';
import 'package:flutter/material.dart';

class SlashedField extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSlashComplete;

  const SlashedField({
    super.key,
    required this.child,
    this.onSlashComplete,
  });

  static final GlobalKey<SlashedFieldState> globalKey =
      GlobalKey<SlashedFieldState>();

  @override
  State<SlashedField> createState() => SlashedFieldState();
}

class SlashedFieldState extends State<SlashedField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _separationAnim; // 分离距离
  late Animation<double> _rotationAnim; // 旋转角度
  late Animation<double> _opacityAnim; // 透明度

  bool _isSlashed = false;
  final Random _random = Random();
  double _direction = 1.0; // 1.0 或 -1.0

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 动画时间缩短，更干脆
    );

    // 1. 分离：向两边快速弹开
    _separationAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // 2. 旋转：持续旋转
    _rotationAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    // 3. 透明度：稍微延迟一点再消失
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50), // 前50%时间保持不透明
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50), // 后50%慢慢消失
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSlashComplete?.call();
      }
    });
  }

  void slash() {
    setState(() {
      _isSlashed = true;
      _direction = _random.nextBool() ? 1.0 : -1.0;
    });
    _controller.forward(from: 0.0);
  }

  void reset() {
    setState(() {
      _isSlashed = false;
    });
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 关键优化：如果不斩击，直接返回 child
    if (!_isSlashed) {
      return RepaintBoundary(child: widget.child);
    }

    // 动画参数
    const double maxSeparation = 100.0; // 飞出距离
    const double maxRotation = 0.4; // 旋转弧度 (约20度)

    return RepaintBoundary(
      child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
          final moveX = _separationAnim.value * maxSeparation * _direction;
          final rotate = _rotationAnim.value * maxRotation * _direction;

        return Stack(
          children: [
              // --- 上半部分 ---
            Transform.translate(
                offset: Offset(-moveX, -moveX * 0.2), // 向左上飞
              child: Transform.rotate(
                  angle: -rotate, // 逆时针转
                  alignment: Alignment.bottomCenter, // 围绕切割线旋转
                child: Opacity(
                    opacity: _opacityAnim.value,
                  child: ClipRect(
                    clipper: _TopHalfClipper(),
                    child: widget.child,
                  ),
                ),
              ),
            ),

              // --- 下半部分 ---
            Transform.translate(
                offset: Offset(moveX, moveX * 0.2), // 向右下飞
              child: Transform.rotate(
                  angle: -rotate, // 跟随上半部分同向旋转
                  alignment: Alignment.topCenter, // 围绕切割线旋转
                child: Opacity(
                    opacity: _opacityAnim.value,
                  child: ClipRect(
                    clipper: _BottomHalfClipper(),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      ),
    );
  }
}

// 辅助类保持不变
class _TopHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, size.height / 2);
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

class _BottomHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height / 2, size.width, size.height);
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
