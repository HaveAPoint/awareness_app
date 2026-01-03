import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../data/database/database.dart';
import 'widgets/mirror_section.dart';
import 'widgets/pending_session_card.dart';
import 'widgets/pending_thought_card.dart';

/// 日记页面 - 待处理事项整合视图
class JournalPage extends StatefulWidget {
  final VoidCallback? onSwitchToFocus;

  const JournalPage({super.key, this.onSwitchToFocus});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  void _showMirrorDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.1,
          vertical: MediaQuery.of(context).size.height * 0.1,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                blurRadius: 30,
                color: Colors.black26,
                offset: Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: const MirrorSection(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            // 主内容 - 使用StreamBuilder实时监听
            StreamBuilder<List<FocusSession>>(
              stream: db.watchPendingReviewSessions(),
              builder: (context, sessionsSnapshot) {
                return StreamBuilder<List<Thought>>(
                  stream: db.watchActiveThoughts(),
                  builder: (context, thoughtsSnapshot) {
                    final sessions = sessionsSnapshot.data ?? [];
                    final thoughts = thoughtsSnapshot.data ?? [];
                    final isLoading = !sessionsSnapshot.hasData || !thoughtsSnapshot.hasData;
                    final totalPending = sessions.length + thoughts.length;

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // 顶部标题
                        SliverToBoxAdapter(
                          child: _buildHeader(totalPending),
                        ),

                        if (isLoading)
                          const SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          )
                        else if (totalPending == 0)
                          SliverFillRemaining(
                            child: _buildEmptyState(),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                // 待确认番茄钟
                                if (sessions.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    icon: Icons.timer_outlined,
                                    title: '待确认',
                                    count: sessions.length,
                                    color: const Color(0xFFF6AD55),
                                  ),
                                  const SizedBox(height: 12),
                                  ...sessions.map((s) => PendingSessionCard(session: s)),
                                  const SizedBox(height: 24),
                                ],

                                // 待处理念头
                                if (thoughts.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    icon: Icons.lightbulb_outline,
                                    title: '念头',
                                    count: thoughts.length,
                                    color: const Color(0xFF9F7AEA),
                                  ),
                                  const SizedBox(height: 12),
                                  ...thoughts.map((t) => PendingThoughtCard(thought: t)),
                                ],

                                const SizedBox(height: 100),
                              ]),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),

            // 小眼睛按钮
            Positioned(
              right: 20,
              bottom: 20,
              child: _buildGlassFab(
                icon: Icons.remove_red_eye_outlined,
                onPressed: _showMirrorDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int totalPending) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.inbox_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '待处理',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                totalPending > 0 ? '$totalPending 项' : '一切就绪',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '没有待处理事项',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildGlassFab({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFEEF2FF).withValues(alpha: 0.95),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.remove_red_eye_outlined,
          color: Color(0xFF6366F1),
          size: 26,
        ),
      ),
    );
  }
}
