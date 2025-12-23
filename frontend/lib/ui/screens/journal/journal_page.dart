import 'dart:ui'; // 用于 ImageFilter 模糊效果
import 'package:flutter/material.dart';
import 'widgets/launchpad_section.dart';
import 'widgets/mirror_section.dart';
import 'widgets/sediment_section.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  // ================== State (状态) ==================
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _collapseIfExpanded() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  // ================== UI Rendering (渲染逻辑) ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 背景色，防止模糊时透视出黑色
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 获取当前的屏幕可用宽度和高度
            // 类似于 C++ GUI 中的 GetClientRect()
            final fullWidth = constraints.maxWidth;
            final safeHeight = constraints.maxHeight;

            return Column(
              // 保持默认的 center，允许子组件自定义宽度
              children: [
                // ------------------------------------------------
                // 1. 顶部区域 (Top Section)
                // ------------------------------------------------
                // 我们希望顶部始终占满屏幕宽度，所以显式设置为 fullWidth
                SizedBox(
                  width: fullWidth,
                  child: _buildShrinkableSection(
                    // 展开时高度 10%，收起时 45%
                    height: _isExpanded ? safeHeight * 0.1 : safeHeight * 0.45,
                    child: const LaunchpadSection(),
                    onTap: _collapseIfExpanded,
                  ),
                ),

                // ------------------------------------------------
                // 2. 中间区域 (Middle Section - The Card)
                // ------------------------------------------------
                GestureDetector(
                  onTap: _toggleExpand,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn, // 物理感更强的曲线
                    // 展开时：宽度为屏幕的 90% (0.9)，配合 Column 的居中，形成悬浮效果
                    // 收起时：宽度为屏幕的 100% (1.0)，占满整行
                    width: _isExpanded ? fullWidth * 0.9 : fullWidth,
                    height: _isExpanded ? safeHeight * 0.8 : safeHeight * 0.1,

                    // 仅保留垂直间距，不需要水平 margin，因为宽度已经通过 width 控制了
                    margin: EdgeInsets.symmetric(
                      vertical: _isExpanded ? 16 : 0,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      // 展开时显示圆角，收起时直角
                      borderRadius: BorderRadius.circular(_isExpanded ? 24 : 0),
                      boxShadow: _isExpanded
                          ? [
                              const BoxShadow(
                                blurRadius: 30, // 阴影模糊度
                                color: Colors.black26, // 阴影颜色
                                spreadRadius: 0,
                                offset: Offset(0, 10), // 阴影向下偏移
                              ),
                            ]
                          : [],
                    ),
                    clipBehavior: Clip.antiAlias, // 抗锯齿裁剪，保证圆角平滑
                    child: const MirrorSection(),
                  ),
                ),

                // ------------------------------------------------
                // 3. 底部区域 (Bottom Section)
                // ------------------------------------------------
                // 底部同样显式占满宽度
                SizedBox(
                  width: fullWidth,
                  child: _buildShrinkableSection(
                    height: _isExpanded ? safeHeight * 0.1 : safeHeight * 0.45,
                    child: const SedimentSection(),
                    onTap: _collapseIfExpanded,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 通用构建函数：处理顶部和底部的收缩、模糊逻辑
  /// [height] : 目标高度
  /// [child]  : 内容组件
  /// [onTap]  : 点击回调
  Widget _buildShrinkableSection({
    required double height,
    required Widget child,
    required VoidCallback onTap,
  }) {
    // 模糊参数：展开时模糊半径为 10，收起时为 0
    final double blurSigma = _isExpanded ? 10.0 : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        height: height,
        clipBehavior: Clip.hardEdge, // 必须裁剪，否则内容可能溢出
        decoration: const BoxDecoration(), // 提供空的 decoration 以支持 clip
        // 模糊层级：ImageFiltered (模糊) -> AnimatedOpacity (透明度) -> Child
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isExpanded ? 0.5 : 1.0, // 展开时变半透明
            child: child,
          ),
        ),
      ),
    );
  }
}
