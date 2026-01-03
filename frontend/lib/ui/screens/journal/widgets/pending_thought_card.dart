import 'package:flutter/material.dart';
import '../../../../data/database/database.dart';
import '../../../../main.dart';

/// 简洁念头卡片 - 左滑显示操作图标
class PendingThoughtCard extends StatefulWidget {
  final Thought thought;

  const PendingThoughtCard({
    super.key,
    required this.thought,
  });

  @override
  State<PendingThoughtCard> createState() => _PendingThoughtCardState();
}

class _PendingThoughtCardState extends State<PendingThoughtCard> {
  bool _isEditing = false;
  bool _isExpanded = false; // 是否展开显示操作按钮
  late TextEditingController _controller;

  // 操作区域宽度: 8 + (44+8)*3 + 8 = 172
  static const double _actionsWidth = 172.0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.thought.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _markResolved() async {
    await db.defuseThought(widget.thought.id);
  }

  Future<void> _delete() async {
    await db.deleteThought(widget.thought.id);
  }

  Future<void> _saveEdit() async {
    if (_controller.text.isNotEmpty && _controller.text != widget.thought.content) {
      await db.updateThoughtContent(widget.thought.id, _controller.text);
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return _buildEditMode();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 52,
      child: Stack(
        children: [
          // 背景操作按钮
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF), // 淡紫色背景
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 8),
                  _buildActionIcon(
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                    onTap: _markResolved,
                  ),
                  _buildActionIcon(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF6366F1),
                    onTap: () => setState(() => _isEditing = true),
                  ),
                  _buildActionIcon(
                    icon: Icons.delete_outline,
                    color: const Color(0xFFEF4444),
                    onTap: _delete,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          // 前景内容卡片
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            left: _isExpanded ? -_actionsWidth : 0,
            right: _isExpanded ? _actionsWidth : 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                // 向左滑展开，向右滑收起
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -100) {
                    setState(() => _isExpanded = true);
                  } else if (details.primaryVelocity! > 100) {
                    setState(() => _isExpanded = false);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF), // 更浅的淡紫色
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9D5FF)), // 淡紫色边框
                  boxShadow: _isExpanded
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(-2, 0),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.thought.content,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF581C87), // 深紫色文字
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatTime(widget.thought.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA855F7), // 紫色时间
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        setState(() => _isExpanded = false);
      },
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildEditMode() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA855F7), width: 2),
      ),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _controller.text = widget.thought.content;
                  setState(() => _isEditing = false);
                },
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA855F7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
