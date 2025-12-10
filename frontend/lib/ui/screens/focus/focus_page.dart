import 'dart:async';
import 'dart:ui'; // 用于 FontFeature
import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

// 引入你的项目文件
import '../../../data/database/database.dart';
import '../../../main.dart'; // 包含全局 db
import '../../../logic/timer/focus_controller.dart'; // 刚才创建的控制器
// 刀光已禁用，保留粒子/斩击依赖
import '../../common/effects/particle_system.dart';
import '../../common/effects/slashed_field.dart';
import 'components/focus_ring.dart';

/// Zen Strike Mode: 专注倒计时 + 禅定斩击输入
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with TickerProviderStateMixin {
  // 逻辑控制器
  late final FocusController _timerController;

  // 输入与UI状态
  late final TextEditingController _textController;
  late final FocusNode _inputFocus;
  late final AnimationController _breathController;

  Size? _canvasSize;
  bool _showDialog = false; // 是否显示斩击弹窗
  String _pendingThought = '';

  // 斩击特效状态（刀光/粒子已禁用，仅占位）
  List<Offset> _bladePoints = [];
  List<Particle> _particles = [];
  final GlobalKey<SlashedFieldState> _slashKey = GlobalKey<SlashedFieldState>();
  final GlobalKey<FocusRingState> _ringKey = GlobalKey<FocusRingState>();
  bool _hasSlashed = false;

  @override
  void initState() {
    super.initState();
    _timerController = FocusController.withCallback(
      onTimerComplete: (secs) async {
        // 结束时也写入一次，确保持久化
        await db.setTimerDurationSeconds(secs);
      },
    );
    _textController = TextEditingController();
    _inputFocus = FocusNode();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);

    _loadTimerDuration();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _textController.dispose();
    _inputFocus.dispose();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _loadTimerDuration() async {
    final seconds = await db.getTimerDurationSeconds(
      defaultSeconds: FocusController.kDefaultFocusTime,
    );
    _timerController.setDuration(Duration(seconds: seconds));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 使用 ListenableBuilder 监听计时器变化
      body: ListenableBuilder(
        listenable: _timerController,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              _canvasSize ??= Size(constraints.maxWidth, constraints.maxHeight);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. 背景层
                  BreathingBackground(animation: _breathController),

                  // 2. 核心内容层 (计时器 + 输入框)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- 计时器区域 (圆环 + 文字) ---
                        Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (_) =>
                              _ringKey.currentState?.pressDown(),
                          onPointerCancel: (_) =>
                              _ringKey.currentState?.pressCancel(),
                          onPointerUp: (_) {
                            _ringKey.currentState?.pressUp();
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onDoubleTap: () {
                              _ringKey.currentState?.pressUp();
                              _handleTimerDoubleTap();
                            },
                            onTap: () {
                              // 单击：仅在空闲/暂停时生效，运行时无效
                              if (_timerController.status ==
                                  TimerStatus.running) {
                                return;
                              }
                              _handleTimerTap();
                              HapticFeedback.selectionClick();
                            },
                            child: SizedBox(
                              width: 300,
                              height: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  FocusRing(
                                    key: _ringKey,
                                    progress: _timerController.progress,
                                    isRunning:
                                        _timerController.status ==
                                        TimerStatus.running,
                                    onTap: () {
                                      // 单击：仅在空闲/暂停时生效，运行时无效
                                      if (_timerController.status ==
                                          TimerStatus.running) {
                                        return;
                                      }
                                      _handleTimerTap();
                                      HapticFeedback.selectionClick();
                                    },
                                  ),
                                  IgnorePointer(
                                    child: Text(
                                      _timerController.timeString,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge
                                          ?.copyWith(
                                            fontSize: 72,
                                            fontWeight: FontWeight.w200,
                                            color: Colors.white,
                                            fontFeatures: [
                                              const FontFeature.tabularFigures(),
                                            ],
                                            shadows: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // --- 念头捕获输入框 (未显示弹窗时显示) ---
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _showDialog ? 0.0 : 1.0, // 弹窗显示时隐藏输入框
                          child: SizedBox(
                            width: 320,
                            child: TextField(
                              controller: _textController,
                              focusNode: _inputFocus,
                              style: const TextStyle(color: Colors.white),
                              cursorColor: Colors.cyanAccent,
                              textInputAction: TextInputAction.done,
                              onSubmitted: _handleSubmit,
                              decoration: const InputDecoration(
                                hintText: "Capture Thought...",
                                hintStyle: TextStyle(
                                  color: Colors.white54,
                                  letterSpacing: 1.2,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),
                      ],
                    ),
                  ),

                  // 3. 斩击交互层 (全屏遮罩 + 手势)
                  if (_showDialog && _canvasSize != null)
                    _SlashDialogOverlay(
                      text: _pendingThought,
                      slashKey: _slashKey,
                      bladePoints: _bladePoints,
                      particles: _particles,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- 逻辑处理方法 ---

  void _handleTimerTap() {
    final status = _timerController.status;
    if (status == TimerStatus.idle || status == TimerStatus.paused) {
      _timerController.startFocus();
    } else if (status == TimerStatus.running) {
      _timerController.pauseFocus();
    }
  }

  void _handleTimerDoubleTap() {
    final status = _timerController.status;
    if (status == TimerStatus.idle) {
      _showDurationPicker();
    } else {
      _timerController.stopFocus();
    }
  }

  Future<void> _handleSubmit(String value) async {
    if (value.trim().isEmpty) return;

    final now = DateTime.now();
    // 写入数据库
    await db
        .into(db.thoughts)
        .insert(
          ThoughtsCompanion(
            id: drift.Value(const Uuid().v4()),
            content: drift.Value(value.trim()),
            category: const drift.Value('inbox'),
            isResolved: const drift.Value(true),
            resolvedAt: drift.Value(now.millisecondsSinceEpoch),
          ),
        );

    _textController.clear();
    _inputFocus.unfocus();
    HapticFeedback.lightImpact();

    // 触发 UI 变化：显示斩击弹窗
    setState(() {
      _pendingThought = value.trim();
      _showDialog = true;
      _bladePoints = [];
      _particles = [];
      _hasSlashed = false;
    });
  }

  void _onPanStart(DragStartDetails details) {
    // 区域触碰即完成切割，不再绘制刀光/粒子
    _triggerSlash();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // 刀光已禁用，滑动事件忽略
  }

  void _onPanEnd(DragEndDetails details) {
    // 延迟关闭弹窗，让用户看完特效
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _showDialog = false;
        _bladePoints = [];
        _particles = [];
        _pendingThought = '';
        _hasSlashed = false;
      });
      // 弹窗关闭后，恢复 SlashedField 状态以备下次使用
      _slashKey.currentState?.reset();
    });
  }

  void _triggerSlash() {
    if (!_hasSlashed) {
      _hasSlashed = true;
      _slashKey.currentState?.slash();
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _showDurationPicker() async {
    final int currentSeconds = _timerController.currentSeconds;
    int initMinutes = (currentSeconds ~/ 60).clamp(0, 120);
    int initSeconds = (currentSeconds % 60).clamp(0, 59);

    int selectedMinutes = initMinutes;
    int selectedSeconds = initSeconds;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '设置倒计时',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 分钟
                    SizedBox(
                      width: 120,
                      child: CupertinoPicker(
                        itemExtent: 36,
                        scrollController: FixedExtentScrollController(
                          initialItem: initMinutes,
                        ),
                        onSelectedItemChanged: (idx) {
                          selectedMinutes = idx;
                        },
                        children: List.generate(
                          121, // 0-120 分钟
                          (i) => Center(
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      ':',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    // 秒
                    SizedBox(
                      width: 120,
                      child: CupertinoPicker(
                        itemExtent: 36,
                        scrollController: FixedExtentScrollController(
                          initialItem: initSeconds,
                        ),
                        onSelectedItemChanged: (idx) {
                          selectedSeconds = idx;
                        },
                        children: List.generate(
                          60, // 0-59 秒
                          (i) => Center(
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('确认'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    final newTotal = selectedMinutes * 60 + selectedSeconds;
    if (newTotal > 0) {
      _timerController.setDuration(Duration(seconds: newTotal));
      // 持久化当前设定，重启后沿用
      await db.setTimerDurationSeconds(newTotal);
      HapticFeedback.selectionClick();
    }
  }
}

class BreathingBackground extends StatelessWidget {
  final Animation<double> animation;
  const BreathingBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final opacity1 = 0.9 + 0.05 * t;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.3,
              colors: [
                const Color(0xFF0A0A12).withOpacity(opacity1), // 中心亮
                const Color(0xFF000000), // 边缘黑
              ],
            ),
          ),
        );
      },
    );
  }
}

// 斩击遮罩层：包含全屏手势检测和居中的 SlashedField
class _SlashDialogOverlay extends StatelessWidget {
  final String text;
  final GlobalKey<SlashedFieldState> slashKey;
  final List<Offset> bladePoints;
  final List<Particle> particles;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  const _SlashDialogOverlay({
    required this.text,
    required this.slashKey,
    required this.bladePoints,
    required this.particles,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // 拦截所有点击
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Stack(
          children: [
            // 半透明遮罩
            Container(color: Colors.black.withOpacity(0.8)),

            // 居中的被斩击物体
            Center(
              child: SlashedField(
                key: slashKey,
                // 注意：这里的 onSlashComplete 可以留空，因为我们在 onPanEnd 里处理了关闭逻辑
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.psychology,
                        color: Colors.cyanAccent,
                        size: 30,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 刀光与粒子效果已禁用

            // 提示文字
            const Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Text(
                "SWIPE TO DEFUSE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white30,
                  letterSpacing: 4,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
