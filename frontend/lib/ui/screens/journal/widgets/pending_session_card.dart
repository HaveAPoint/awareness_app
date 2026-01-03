import 'package:flutter/material.dart';
import '../../../../data/database/database.dart';
import '../../../../main.dart';

/// 简洁番茄钟卡片 - 左滑显示编辑按钮
class PendingSessionCard extends StatefulWidget {
  final FocusSession session;

  const PendingSessionCard({
    super.key,
    required this.session,
  });

  @override
  State<PendingSessionCard> createState() => _PendingSessionCardState();
}

class _PendingSessionCardState extends State<PendingSessionCard> {
  bool _isEditing = false;
  bool _isExpanded = false;
  int _selectedQuality = 3;
  late TextEditingController _noteController;

  // 操作区域宽度：只有一个编辑按钮
  static const double _actionsWidth = 60.0;

  @override
  void initState() {
    super.initState();
    _selectedQuality = widget.session.focusQuality ?? 3;
    _noteController = TextEditingController(text: widget.session.reviewNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    return '$mins分钟';
  }

  Future<void> _save() async {
    await db.updateFocusSessionReview(
      sessionId: widget.session.id,
      focusQuality: _selectedQuality,
      reviewNote: _noteController.text.isEmpty ? null : _noteController.text,
    );
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = false;
                        _isEditing = true;
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6AD55).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
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
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -100) {
                    setState(() => _isExpanded = true);
                  } else if (details.primaryVelocity! > 100) {
                    setState(() => _isExpanded = false);
                  }
                }
              },
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final needsQuality = widget.session.focusQuality == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE4B5)),
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
          Text(
            _formatTime(widget.session.startTime),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDuration(widget.session.durationSeconds),
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber.shade700,
            ),
          ),
          const Spacer(),
          if (needsQuality)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF6AD55).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '待评分',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF92400E),
                ),
              ),
            )
          else
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < _selectedQuality ? Icons.star : Icons.star_border,
                  size: 14,
                  color: const Color(0xFFF6AD55),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF6AD55), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatTime(widget.session.startTime),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDuration(widget.session.durationSeconds),
                style: TextStyle(fontSize: 14, color: Colors.amber.shade700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('专注质量', style: TextStyle(fontSize: 13, color: Color(0xFF92400E))),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final quality = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedQuality = quality),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    _selectedQuality >= quality ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF6AD55),
                    size: 28,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Text('简短反思', style: TextStyle(fontSize: 13, color: Color(0xFF92400E))),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '记录这段时间的状态...',
              hintStyle: TextStyle(color: Colors.amber.shade300),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFFE4B5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFFE4B5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFF6AD55), width: 2),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF6AD55),
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
