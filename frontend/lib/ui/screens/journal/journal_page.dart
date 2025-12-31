import 'dart:ui'; // 用于 ImageFilter 模糊效果
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../main.dart'; // for db
import '../../../../data/database/database.dart';
import 'widgets/launchpad_section.dart';
import 'widgets/mirror_section.dart';
import 'widgets/sediment_section.dart';

class JournalPage extends StatefulWidget {
  final VoidCallback? onSwitchToFocus;

  const JournalPage({super.key, this.onSwitchToFocus});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

// 定义页面状态枚举
enum JournalState {
  idle, // 默认状态：Top 50%, Bottom 50%
  launchpadExpanded, // 发射台展开：Top 90%, Bottom 10%
}

class _JournalPageState extends State<JournalPage> {
  // ================== State (状态) ==================
  JournalState _currentState = JournalState.idle;

  // ================== Database Logic ==================
  Stream<List<Objective>> _objectivesStream() {
    // Launchpad只显示进行中的目标（可以绑定番茄钟）
    return (db.select(db.objectives)
          ..where((t) => t.status.equals('active'))
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.createdAt,
              mode: drift.OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<void> _handleObjectiveToggle(
    Objective objective,
    bool isCompleted,
  ) async {
    final newStatus = isCompleted ? 'completed' : 'active';
    await (db.update(
      db.objectives,
    )..where((t) => t.id.equals(objective.id))).write(
      ObjectivesCompanion(
        status: drift.Value(newStatus),
        updatedAt: drift.Value(DateTime.now()),
        isSynced: const drift.Value(false),
      ),
    );
  }

  void _toggleLaunchpad() {
    setState(() {
      if (_currentState == JournalState.launchpadExpanded) {
        _currentState = JournalState.idle;
      } else {
        _currentState = JournalState.launchpadExpanded;
      }
    });
  }

  void _resetState() {
    if (_currentState != JournalState.idle) {
      setState(() {
        _currentState = JournalState.idle;
      });
    }
  }

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
                spreadRadius: 0,
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

  // ================== UI Rendering (渲染逻辑) ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 背景色，防止模糊时透视出黑色
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth;
            final safeHeight = constraints.maxHeight;

            // 根据状态计算各部分高度比例
            double topHeightRatio;
            double bottomHeightRatio;

            switch (_currentState) {
              case JournalState.idle:
                topHeightRatio = 0.382;
                bottomHeightRatio = 0.618;
                break;
              case JournalState.launchpadExpanded:
                topHeightRatio = 0.90;
                bottomHeightRatio = 0.10;
                break;
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // ------------------------------------------------
                    // 1. 顶部区域 (Launchpad Section)
                    // ------------------------------------------------
                    SizedBox(
                      width: fullWidth,
                      child: _buildSectionContainer(
                        height: safeHeight * topHeightRatio,
                        isExpanded: _currentState == JournalState.launchpadExpanded,
                        isBlurred: false,
                        onTap: _toggleLaunchpad,
                        child: StreamBuilder<List<Objective>>(
                          stream: _objectivesStream(),
                          builder: (context, snapshot) {
                            final objectives = snapshot.data ?? [];
                            return LaunchpadSection(
                              objectives: objectives,
                              onObjectiveToggle: _handleObjectiveToggle,
                              onSwitchToFocus: widget.onSwitchToFocus,
                            );
                          },
                        ),
                      ),
                    ),

                    // ------------------------------------------------
                    // 2. 底部区域 (Sediment Section)
                    // ------------------------------------------------
                    SizedBox(
                      width: fullWidth,
                      child: _buildSectionContainer(
                        height: safeHeight * bottomHeightRatio,
                        isExpanded: false,
                        isBlurred: _currentState != JournalState.idle,
                        onTap: _resetState,
                        child: const SedimentSection(),
                      ),
                    ),
                  ],
                ),
                
                // ------------------------------------------------
                // 3. 右下角悬浮按钮 (Mirror 入口)
                // ------------------------------------------------
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: _showMirrorDialog,
                    backgroundColor: Colors.blue,
                    child: const Icon(
                      Icons.remove_red_eye,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 通用构建函数：处理简单的拉伸和模糊逻辑 (无卡片浮动特效)
  Widget _buildSectionContainer({
    required double height,
    required bool isExpanded,
    required bool isBlurred,
    required Widget child,
    required VoidCallback onTap,
  }) {
    final double blurSigma = isBlurred ? 10.0 : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        height: height,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isBlurred ? 0.5 : 1.0,
            child: child,
          ),
        ),
      ),
    );
  }
}
