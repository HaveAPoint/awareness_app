import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 长按蓄力的液态脉冲按钮，适合“收藏/保存”类交互。
class LiquidPulseButton extends StatefulWidget {
  final IconData icon; // 未选中时的图标 (通常是线框)
  final IconData filledIcon; // 选中/蓄力满时的图标 (通常是实心)
  final Color activeColor; // 填充颜色
  final Color inactiveColor; // 底色
  final double size;
  final Duration duration; // 长按蓄力需要多久
  final VoidCallback onCompleted; // 完成时的回调

  const LiquidPulseButton({
    super.key,
    this.icon = Icons.favorite_border_rounded,
    this.filledIcon = Icons.favorite_rounded,
    this.activeColor = const Color(0xFFFF5252), // 番茄红
    this.inactiveColor = const Color(0xFFBDBDBD),
    this.size = 48.0,
    this.duration = const Duration(milliseconds: 1200), // 1.2秒蓄力
    required this.onCompleted,
  });

  @override
  State<LiquidPulseButton> createState() => _LiquidPulseButtonState();
}

class _LiquidPulseButtonState extends State<LiquidPulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 定义按压时的缩放动画：按下时缩小到 0.85，产生“受力感”
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        // 前半段快速缩小，后半段保持
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // 1. 触发震动反馈 (Heavy Impact)
      HapticFeedback.heavyImpact();

      // 2. 标记完成
      setState(() {
        _isCompleted = true;
      });

      // 3. 触发回调
      widget.onCompleted();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- 交互逻辑 ---

  void _handleTapDown(TapDownDetails details) {
    if (_isCompleted) return;
    // 触感反馈 (Light)
    HapticFeedback.selectionClick();
    // 开始蓄力
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isCompleted) return;
    // 如果没完成就松手了，倒放（回退）
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isCompleted) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // 如果已经完成，显示一个固定的完成态（或按需重置）
    if (_isCompleted) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut, // 弹性果冻效果
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Icon(
              widget.filledIcon,
              size: widget.size,
              color: widget.activeColor,
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      // 使用 AnimatedBuilder 监听 controller 变化
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value, // 应用按压缩放
            child: Stack(
              children: [
                // 1. 底层：灰色线框
                Icon(
                  widget.icon,
                  size: widget.size,
                  color: widget.inactiveColor,
                ),
                // 2. 顶层：彩色实心，通过 ClipRect 进行裁剪
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter, // 从底部向上填充
                    heightFactor: _controller.value, // 核心：0.0 -> 1.0
                    child: Icon(
                      widget.filledIcon,
                      size: widget.size,
                      color: widget.activeColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

