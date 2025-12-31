import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../data/database/database.dart';
import '../../../../main.dart'; // for focusSessionState

class LaunchpadSection extends StatefulWidget {
  final List<Objective> objectives;
  final Function(Objective objective, bool isCompleted) onObjectiveToggle;
  final VoidCallback? onSwitchToFocus;

  const LaunchpadSection({
    super.key,
    required this.objectives,
    required this.onObjectiveToggle,
    this.onSwitchToFocus,
  });

  @override
  State<LaunchpadSection> createState() => _LaunchpadSectionState();
}

class _LaunchpadSectionState extends State<LaunchpadSection> {
  String? _longPressingId;
  Timer? _longPressTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Material 3 风格
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      // 移除硬编码颜色，使用透明或主题色
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'LAUNCHPAD',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 目标列表
          Expanded(
            child: widget.objectives.isEmpty
                ? Center(
                    child: Text(
                      'No active objectives',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: widget.objectives.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final objective = widget.objectives[index];
                      return _buildObjectiveItem(context, objective);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveItem(BuildContext context, Objective objective) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = objective.status == 'completed';
    final isArchived = objective.status == 'archived';
    final canBind = objective.status == 'active'; // 只有active状态可以绑定
    final progress = objective.calculatedProgress; // 0.0 - 100.0 (数据库存储的是百分比)
    final isLongPressing = _longPressingId == objective.id;

    return Listener(
      onPointerDown: (_) {
        if (!canBind) return; // 已完成或归档的目标不能绑定

        setState(() {
          _longPressingId = objective.id;
        });
        HapticFeedback.selectionClick();

        // 1秒后触发关联
        _longPressTimer?.cancel();
        _longPressTimer = Timer(const Duration(seconds: 1), () {
          if (_longPressingId == objective.id && mounted) {
            focusSessionState.linkObjective(objective.id, objective.title);
            HapticFeedback.heavyImpact();
            setState(() {
              _longPressingId = null;
            });

            // 显示提示
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已关联目标: ${objective.title}'),
                duration: const Duration(seconds: 1),
              ),
            );

            // 跳转到 Focus 页面
            widget.onSwitchToFocus?.call();
          }
        });
      },
      onPointerUp: (_) {
        _longPressTimer?.cancel();
        setState(() {
          _longPressingId = null;
        });
      },
      onPointerCancel: (_) {
        _longPressTimer?.cancel();
        setState(() {
          _longPressingId = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isLongPressing
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isLongPressing ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isLongPressing
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 目标名称
            Text(
              objective.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isCompleted
                    ? colorScheme.onSurfaceVariant.withOpacity(0.6)
                    : colorScheme.onSurface,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: colorScheme.outline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // 进度条和百分比
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress / 100.0, // 转换为0-1范围
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: isCompleted
                        ? colorScheme.tertiary
                        : colorScheme.primary,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${progress.toInt()}%', // 直接使用，不再乘100
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
