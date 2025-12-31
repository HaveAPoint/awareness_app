import 'dart:async';
import 'dart:ui'; // 用于 FontFeature
import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

// 引入你的项目文件
import '../../../data/database/database.dart';
import '../../../main.dart'; // 包含全局 db 和 focusSessionState
import '../../../logic/timer/focus_controller.dart'; // 刚才创建的控制器
// 刀光已禁用，保留粒子/斩击依赖
import '../../common/effects/particle_system.dart';
import '../../common/effects/slashed_field.dart';
import 'components/focus_ring.dart';
import 'components/pomodoro_progress_row.dart';

/// 时长类型枚举
enum DurationType {
  work, // 工作时长
  rest, // 休息时长
  longRest, // 长休息时长
}

/// Zen Strike Mode: 专注倒计时 + 禅定斩击输入
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with TickerProviderStateMixin {
  // 逻辑控制器 - 改为可空，在数据加载后初始化
  FocusController? _timerController;

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
  bool _inspirationSaved = false;
  late final AnimationController _pulseController;
  bool _pulseCompleted = false;

  // 异步初始化数据
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _inputFocus = FocusNode();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener(_onPulseStatus);

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);

    // 确保页面初始不自动聚焦输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocus.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
    });

    // 在进入页面前预加载时间
    _initFuture = _initializeController();
  }

  Future<void> _initializeController() async {
    // 如果控制器已经存在，不要重新创建（防止重复初始化导致数据丢失）
    if (_timerController != null) {
      debugPrint('[FocusPage] _initializeController: 控制器已存在，跳过初始化');
      return;
    }

    debugPrint('[FocusPage] _initializeController: 开始初始化控制器');
    // 从数据库读取/回填工作时长
    final workSecondsFromDb = await db.getTimerDurationSeconds();
    int workSeconds;
    if (workSecondsFromDb == null) {
      workSeconds = FocusController.kFallbackWorkSeconds;
      await db.setTimerDurationSeconds(workSeconds);
    } else {
      workSeconds = workSecondsFromDb;
    }

    // 从数据库读取/回填休息时长
    final restSecondsFromDb = await db.getRestDurationSeconds();
    int restSeconds;
    if (restSecondsFromDb == null) {
      restSeconds = FocusController.kFallbackRestSeconds;
      await db.setRestDurationSeconds(restSeconds);
    } else {
      restSeconds = restSecondsFromDb;
    }

    // 从数据库读取/回填长休息时长
    final longRestSecondsFromDb = await db.getLongRestDurationSeconds();
    int longRestSeconds;
    if (longRestSecondsFromDb == null) {
      longRestSeconds = FocusController.kFallbackLongRestSeconds;
      await db.setLongRestDurationSeconds(longRestSeconds);
    } else {
      longRestSeconds = longRestSecondsFromDb;
    }

    // 初始化控制器
    debugPrint(
      '[FocusPage] 创建 FocusController: workSeconds=$workSeconds (${workSeconds ~/ 60}分钟), restSeconds=$restSeconds, longRestSeconds=$longRestSeconds (${longRestSeconds ~/ 60}分钟)',
    );
    _timerController = FocusController(
      workSeconds: workSeconds,
      restSeconds: restSeconds,
      longRestSeconds: longRestSeconds,
      onTimerComplete: () {
        // 倒计时归零时触发（播放提示音或震动）
        HapticFeedback.mediumImpact();
      },
    );
    debugPrint('[FocusPage] 控制器创建完成');

    if (mounted) {
      setState(() {}); // 触发重建以显示控制器
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timerController?.dispose();
    _textController.dispose();
    _inputFocus.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 FutureBuilder 等待控制器初始化完成
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        // 如果还在加载，显示加载指示器
        if (snapshot.connectionState != ConnectionState.done ||
            _timerController == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          // 外层捕获点击以收起输入焦点
          body: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: _unfocusAll,
            child: ListenableBuilder(
              listenable: _timerController!,
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    _canvasSize ??= Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. 背景层
                        BreathingBackground(animation: _breathController),

                        // 2. 右上角任务标签（关联状态）
                        ListenableBuilder(
                          listenable: focusSessionState,
                          builder: (context, _) {
                            if (!focusSessionState.hasLink) {
                              return const SizedBox.shrink();
                            }
                            return SafeArea(
                              child: Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: _showUnlinkDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.link_rounded,
                                          size: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          focusSessionState
                                                  .linkedObjectiveTitle ??
                                              '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // 3. 核心内容层 (计时器 + 输入框)
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
                                  onLongPress: () {
                                    // 长按：在 restIdle 状态时进入长休息
                                    if (_timerController?.status ==
                                        FocusStatus.restIdle) {
                                      debugPrint('[FocusPage] 长按触发，进入长休息');
                                      _timerController!.startLongRest();
                                      HapticFeedback.mediumImpact();
                                    }
                                  },
                                  onTap: () {
                                    // 单击：仅在空闲时生效，运行时无效
                                    if (_timerController?.isActive ?? false) {
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
                                          progress:
                                              _timerController?.progress ?? 0.0,
                                          isRunning:
                                              _timerController?.isActive ??
                                              false,
                                          isResting:
                                              _timerController?.isResting ??
                                              false,
                                          onTap: () {
                                            // 单击：仅在空闲时生效，运行时无效
                                            if (_timerController?.isActive ??
                                                false) {
                                              return;
                                            }
                                            _handleTimerTap();
                                            HapticFeedback.selectionClick();
                                          },
                                        ),
                                        IgnorePointer(
                                          child: Text(
                                            _timerController?.timeString ??
                                                '00:00',
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayLarge
                                                ?.copyWith(
                                                  fontSize: 72,
                                                  fontWeight: FontWeight.w200,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                  fontFeatures: [
                                                    const FontFeature.tabularFigures(),
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

                              // --- 番茄钟进度显示行 ---
                              PomodoroProgressRow(
                                currentStepIndex:
                                    _timerController?.currentRoundIndex ?? 0,
                                enableTap:
                                    !(_timerController?.isActive ?? true),
                                onStageTap: (stage, index) =>
                                    _handleStageTap(stage, index),
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
                                    autofocus: false,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                    cursorColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: _handleSubmit,
                                    decoration: InputDecoration(
                                      hintText: "Capture Thought...",
                                      hintStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.7),
                                        letterSpacing: 1.2,
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outlineVariant,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
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
                            onTap: _triggerSlash,
                            onLongPressStart: _startInspirationPulse,
                            onLongPressEnd: _cancelInspirationPulse,
                            pulseAnimation: _pulseController,
                            pulseCompleted: _pulseCompleted,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --- 逻辑处理方法 ---

  void _handleTimerTap() {
    if (_timerController == null) {
      debugPrint('[FocusPage] _handleTimerTap: 控制器为 null，返回');
      return;
    }
    final status = _timerController!.status;
    debugPrint('[FocusPage] _handleTimerTap: 当前状态=$status');

    // 单击：在空闲状态时开始计时
    if (status == FocusStatus.idle) {
      debugPrint('[FocusPage] 调用 startWork()');
      _timerController!.startWork();
    } else if (status == FocusStatus.restIdle) {
      debugPrint('[FocusPage] 调用 startRest()');
      _timerController!.startRest();
    } else if (status == FocusStatus.longRestIdle) {
      debugPrint('[FocusPage] 调用 startLongRest()');
      _timerController!.startLongRest();
    }
    // 运行时单击无效（已在 UI 层过滤）
  }

  void _handleTimerDoubleTap() {
    if (_timerController == null) return;
    final status = _timerController!.status;

    // 双击逻辑：
    // 1. 工作空闲状态 -> 显示工作时长选择器
    if (status == FocusStatus.idle) {
      _showDurationPicker(durationType: DurationType.work);
    }
    // 2. 工作运行/超时状态 -> 停止工作
    //    - running 状态 -> 回到 idle
    //    - extending 状态 -> 进入 restIdle
    else if (status == FocusStatus.running || status == FocusStatus.extending) {
      _timerController!.stopWork();
    }
    // 3. 休息空闲状态 -> 显示休息时长选择器
    else if (status == FocusStatus.restIdle) {
      _showDurationPicker(durationType: DurationType.rest);
    }
    // 4. 休息运行/超时状态 -> 停止休息
    //    - restRunning 状态 -> 回到 restIdle
    //    - restExtending 状态 -> 进入 idle（工作空闲）
    else if (status == FocusStatus.restRunning ||
        status == FocusStatus.restExtending) {
      _timerController!.stopRest();
    }
    // 5. 长休息空闲状态 -> 显示长休息时长选择器
    else if (status == FocusStatus.longRestIdle) {
      _showDurationPicker(durationType: DurationType.longRest);
    }
    // 6. 长休息运行/超时状态 -> 停止长休息
    else if (status == FocusStatus.longRestRunning ||
        status == FocusStatus.longRestExtending) {
      _timerController!.stopLongRest();
    }
  }

  void _unfocusAll() {
    _inputFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// idle 状态下点击阶段图标切换到指定阶段
  void _handleStageTap(PomodoroStage stage, int index) {
    if (_timerController == null) return;
    if (_timerController!.isActive) return; // 仅空闲时允许切换
    _timerController!.selectStageByIndex(index);
    HapticFeedback.selectionClick();
  }

  Future<void> _handleSubmit(String value) async {
    if (value.trim().isEmpty) return;

    // 写入数据库
    await db
        .into(db.thoughts)
        .insert(
          ThoughtsCompanion(
            id: drift.Value(const Uuid().v4()),
            content: drift.Value(value.trim()),
            type: const drift.Value('todo'),
            isResolved: const drift.Value(true),
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
    _closeSlashDialog();
  }

  void _onPulseStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _pulseCompleted = true;
      });
      debugPrint('[FocusPage] pulse completed -> save inspiration');
      HapticFeedback.heavyImpact();
      _saveInspiration();
    }
  }

  void _startInspirationPulse(LongPressStartDetails details) {
    if (_pendingThought.trim().isEmpty) return;
    debugPrint('[FocusPage] pulse start, text="${_pendingThought.trim()}"');
    setState(() {
      _pulseCompleted = false;
    });
    _pulseController.reset();
    HapticFeedback.selectionClick();
    _pulseController.forward();
  }

  void _cancelInspirationPulse(LongPressEndDetails details) {
    if (_pulseCompleted) return;
    debugPrint('[FocusPage] pulse cancel (not completed)');
    setState(() {
      _pulseCompleted = false;
    });
    _pulseController.reverse();
  }

  void _triggerSlash() {
    if (!_hasSlashed) {
      _hasSlashed = true;
      _slashKey.currentState?.slash();
      HapticFeedback.mediumImpact();
      _closeSlashDialog();
    }
  }

  Future<void> _saveInspiration() async {
    if (_inspirationSaved || _pendingThought.trim().isEmpty) return;
    _inspirationSaved = true;
    try {
      final now = DateTime.now();
      await db
          .into(db.thoughts)
          .insert(
            ThoughtsCompanion(
              id: drift.Value(const Uuid().v4()),
              content: drift.Value(_pendingThought.trim()),
              type: const drift.Value('idea'),
              isResolved: const drift.Value(false),
              createdAt: drift.Value(now),
              isSynced: const drift.Value(false),
            ),
          );
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('[FocusPage] ❌ 保存灵感失败: $e');
    } finally {
      _closeSlashDialog();
    }
  }

  void _closeSlashDialog() {
    // 延迟关闭弹窗，让用户看完特效
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _showDialog = false;
        _bladePoints = [];
        _particles = [];
        _pendingThought = '';
        _hasSlashed = false;
        _inspirationSaved = false;
        _pulseController.stop();
        _pulseController.reset();
        _pulseCompleted = false;
      });
      // 弹窗关闭后，恢复 SlashedField 状态以备下次使用
      _slashKey.currentState?.reset();
      // 如果存在导航栈（例如未来嵌入单独路由），确保返回上一层
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _showDurationPicker({required DurationType durationType}) async {
    if (_timerController == null) return;

    // 根据 durationType 决定是修改哪种时长
    int currentSeconds;
    String title;
    if (durationType == DurationType.rest) {
      currentSeconds =
          _timerController?.restDuration ??
          FocusController.kFallbackRestSeconds;
      title = '设置休息时长';
      debugPrint(
        '[FocusPage] _showDurationPicker: 读取休息时长=$currentSeconds (${currentSeconds ~/ 60}分钟)',
      );
    } else if (durationType == DurationType.longRest) {
      currentSeconds =
          _timerController?.longRestDuration ??
          FocusController.kFallbackLongRestSeconds;
      title = '设置长休息时长';
      debugPrint(
        '[FocusPage] _showDurationPicker: 读取长休息时长=$currentSeconds (${currentSeconds ~/ 60}分钟)',
      );
    } else {
      currentSeconds =
          _timerController?.workDuration ??
          FocusController.kFallbackWorkSeconds;
      title = '设置工作时长';
      debugPrint(
        '[FocusPage] _showDurationPicker: 读取工作时长=$currentSeconds (${currentSeconds ~/ 60}分钟)',
      );
    }
    int initMinutes = (currentSeconds ~/ 60).clamp(0, 120);
    int initSeconds = (currentSeconds % 60).clamp(0, 59);

    int selectedMinutes = initMinutes;
    int selectedSeconds = initSeconds;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
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
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      ':',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 20,
                      ),
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
                              style: TextStyle(
                                color: colorScheme.onSurface,
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
    debugPrint(
      '[FocusPage] _showDurationPicker: 用户选择的新时长=$newTotal (${newTotal ~/ 60}分钟), durationType=$durationType',
    );
    if (newTotal > 0 && _timerController != null) {
      if (durationType == DurationType.rest) {
        // 更新休息时长
        debugPrint('[FocusPage] 调用 updateSettings(newRestSeconds: $newTotal)');
        _timerController!.updateSettings(newRestSeconds: newTotal);
        await db.setRestDurationSeconds(newTotal);
      } else if (durationType == DurationType.longRest) {
        // 更新长休息时长
        debugPrint(
          '[FocusPage] 调用 updateSettings(newLongRestSeconds: $newTotal)',
        );
        _timerController!.updateSettings(newLongRestSeconds: newTotal);
        await db.setLongRestDurationSeconds(newTotal);
      } else {
        // 更新工作时长
        debugPrint('[FocusPage] 调用 updateSettings(newWorkSeconds: $newTotal)');
        _timerController!.updateSettings(newWorkSeconds: newTotal);
        await db.setTimerDurationSeconds(newTotal);
      }
      HapticFeedback.selectionClick();
    }
  }

  /// 显示取消关联的确认弹窗
  Future<void> _showUnlinkDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出关联模式？'),
        content: const Text('退出后将重置当前番茄钟进度'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 清除关联
      focusSessionState.clearLink();
      // 重置番茄钟
      _timerController?.reset();
      HapticFeedback.mediumImpact();
    }
  }
}

class BreathingBackground extends StatelessWidget {
  final Animation<double> animation;
  const BreathingBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        // 调整呼吸幅度和颜色混合
        // 使用 primaryContainer 作为中心亮色，surface 作为边缘色
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.3,
              colors: [
                Color.lerp(
                  colorScheme.surface,
                  colorScheme.primaryContainer,
                  0.15 + 0.05 * t,
                )!, // 中心微亮
                colorScheme.surface, // 边缘保持背景色
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
  final VoidCallback onTap;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressEndCallback onLongPressEnd;
  final Animation<double> pulseAnimation;
  final bool pulseCompleted;

  const _SlashDialogOverlay({
    required this.text,
    required this.slashKey,
    required this.bladePoints,
    required this.particles,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.pulseAnimation,
    required this.pulseCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // 拦截所有点击
        onTap: onTap, // 单击触发斩击动画
        onLongPressStart: onLongPressStart,
        onLongPressEnd: onLongPressEnd,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Stack(
          children: [
            // 半透明遮罩
            Container(
              color: Theme.of(context).colorScheme.scrim.withOpacity(0.6),
            ),

            // 居中的被斩击物体 + 液态蓄力动画（固定尺寸）
            Center(
              child: SizedBox(
                width: 300,
                height: 110,
                child: SlashedField(
                  key: slashKey,
                  // 注意：这里的 onSlashComplete 可以留空，因为我们在 onPanEnd 里处理了关闭逻辑
                  child: AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (context, _) {
                      final double t = pulseAnimation.value.clamp(0.0, 1.0);
                      final colorScheme = Theme.of(context).colorScheme;
                      // 长按蓄力时轻微下压，完成后弹性回弹
                      final double targetScale = pulseCompleted
                          ? 1.08
                          : (1.0 - 0.08 * t);
                      return AnimatedScale(
                        scale: targetScale,
                        duration: pulseCompleted
                            ? const Duration(milliseconds: 240)
                            : const Duration(milliseconds: 120),
                        curve: pulseCompleted
                            ? Curves.elasticOut
                            : Curves.easeOut,
                        child: Stack(
                          children: [
                            // 基础卡片
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 底部向上填充的“液态”效果
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  heightFactor: t,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(
                                        0.25,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 内容层
                            Positioned.fill(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    text,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 18,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 刀光与粒子效果已禁用
          ],
        ),
      ),
    );
  }
}
