import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:awareness_app/data/models/goal_models.dart';
import 'key_result_status_icon.dart';
import 'progress_badge.dart';

/// 可滑动的 Key Result 行组件
/// - 左滑显示绿色背景 + 播放图标，触发 onStartFocus
/// - 已完成的KR左滑显示橙色背景 + 撤销图标，触发 onUncomplete
/// - 长按2秒标记为完成，触发 onComplete
/// - 点击触发 onEdit
class KeyResultRow extends StatefulWidget {
  final KeyResultModel keyResult;
  final VoidCallback? onStartFocus;
  final VoidCallback? onEdit;
  final VoidCallback? onComplete;
  final VoidCallback? onUncomplete; // 新增：取消完成回调
  final Color? accentColor;

  const KeyResultRow({
    super.key,
    required this.keyResult,
    this.onStartFocus,
    this.onEdit,
    this.onComplete,
    this.onUncomplete,
    this.accentColor,
  });

  @override
  State<KeyResultRow> createState() => _KeyResultRowState();
}

class _KeyResultRowState extends State<KeyResultRow>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  bool _hasTriggered = false;

  // 长按相关
  Timer? _longPressTimer;
  bool _isLongPressing = false;
  double _longPressProgress = 0.0; // 0.0 - 1.0

  static const double _triggerThreshold = 80.0;
  static const double _maxDrag = 100.0;
  static const Color _focusGreen = Color(0xFF10B981);
  static const Color _uncompleteOrange = Color(0xFFF59E0B); // 取消完成的橙色
  static const Duration _longPressDuration = Duration(seconds: 2);

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    // 如果已完成，不响应长按
    if (widget.keyResult.isCompleted) return;

    _isLongPressing = true;
    _longPressProgress = 0.0;
    HapticFeedback.lightImpact();

    // 使用周期性定时器更新进度
    const updateInterval = Duration(milliseconds: 50);
    final totalUpdates = _longPressDuration.inMilliseconds ~/ updateInterval.inMilliseconds;
    int currentUpdate = 0;

    _longPressTimer = Timer.periodic(updateInterval, (timer) {
      if (!_isLongPressing) {
        timer.cancel();
        return;
      }

      currentUpdate++;
      setState(() {
        _longPressProgress = currentUpdate / totalUpdates;
      });

      if (currentUpdate >= totalUpdates) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        widget.onComplete?.call();
        setState(() {
          _isLongPressing = false;
          _longPressProgress = 0.0;
        });
      }
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _isLongPressing = false;
    _longPressTimer?.cancel();
    setState(() {
      _longPressProgress = 0.0;
    });
  }

  void _onLongPressCancel() {
    _isLongPressing = false;
    _longPressTimer?.cancel();
    setState(() {
      _longPressProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.keyResult.isCompleted;
    final bgColor = isCompleted ? _uncompleteOrange : _focusGreen;
    final bgIcon = isCompleted ? Icons.undo_rounded : Icons.play_arrow_rounded;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: widget.onEdit,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onLongPressCancel: _onLongPressCancel,
        child: SizedBox(
          height: 44,
          child: Stack(
            children: [
              // 背景层：根据完成状态显示不同颜色和图标
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    color: bgColor.withValues(
                      alpha: (-_dragExtent / _triggerThreshold).clamp(0.0, 1.0),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 100),
                        opacity:
                            (-_dragExtent / _triggerThreshold).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale:
                              (0.5 + (-_dragExtent / _triggerThreshold) * 0.5)
                                  .clamp(0.5, 1.0),
                          child: Icon(
                            bgIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 前景层：内容行
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                transform: Matrix4.translationValues(_dragExtent, 0, 0),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // 三态状态图标
                      KeyResultStatusIcon(
                        progress: widget.keyResult.progress,
                        size: 18,
                        activeColor:
                            widget.accentColor ?? const Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 10),

                      // 标题 - 使用 Expanded + Flexible 确保不溢出
                      Expanded(
                        child: Text(
                          widget.keyResult.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            decoration: widget.keyResult.progress >= 1.0
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 进度徽章 - 固定宽度，不被挤压
                      ProgressBadge(progress: widget.keyResult.progress),
                    ],
                  ),
                ),
              ),

              // 长按进度覆盖层
              if (_longPressProgress > 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _focusGreen.withValues(alpha: 0.2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _longPressProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: _focusGreen.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    _hasTriggered = false;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      // 只允许向左滑动（负方向）
      _dragExtent = (_dragExtent + details.delta.dx).clamp(-_maxDrag, 0.0);

      // 触发震动反馈
      if (-_dragExtent >= _triggerThreshold && !_hasTriggered) {
        _hasTriggered = true;
        HapticFeedback.mediumImpact();
      } else if (-_dragExtent < _triggerThreshold && _hasTriggered) {
        _hasTriggered = false;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (-_dragExtent >= _triggerThreshold) {
      HapticFeedback.heavyImpact();
      // 根据完成状态触发不同回调
      if (widget.keyResult.isCompleted) {
        widget.onUncomplete?.call();
      } else {
        widget.onStartFocus?.call();
      }
    }

    // 回弹动画
    setState(() {
      _dragExtent = 0;
    });
  }
}
