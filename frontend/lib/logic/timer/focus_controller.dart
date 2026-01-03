import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../main.dart'; // for focusSessionState, db
import '../../data/database/database.dart';

// 1. 扩展状态定义
enum FocusStatus {
  idle, // 工作-空闲
  running, // 工作-倒计时中
  extending, // 工作-超时正计时中

  restIdle, // 休息-空闲
  restRunning, // 休息-倒计时中
  restExtending, // 休息-超时正计时中

  longRestIdle, // 长休息-空闲
  longRestRunning, // 长休息-倒计时中
  longRestExtending, // 长休息-超时正计时中
}

class FocusController extends ChangeNotifier {
  // 仅作为缺省值，防止数据库读取失败
  static const int kFallbackWorkSeconds = 25 * 60;
  static const int kFallbackRestSeconds = 5 * 60;
  static const int kFallbackLongRestSeconds = 15 * 60; // 默认长休息时长：15分钟

  Timer? _timer;
  int _currentSeconds; // 核心变量：正数代表剩余时间，负数代表超时时间
  int _targetSeconds; // 记录本次设定的总时长，用于计算进度

  int _workDuration; // 当前设定的工作时长
  int _restDuration; // 当前设定的休息时长
  int _longRestDuration; // 当前设定的长休息时长

  FocusStatus _status = FocusStatus.idle;

  // 工作-休息循环状态跟踪
  // 循环模式：工作 -> 休息 -> 工作 -> 休息 -> 工作 -> 休息 -> 工作（共7步）
  // 0: 工作1, 1: 休息1, 2: 工作2, 3: 休息2, 4: 工作3, 5: 休息3, 6: 工作4
  int _currentCycleStep = 0; // 当前会话的循环步骤（每次启动时重置为0）
  int _persistedCycleCount = 0; // 当前会话的循环计数
  bool _isInitialized = false; // 是否已完成初始化

  // 番茄钟会话记录
  int? _sessionStartTime; // 工作开始时间（Unix秒）

  // 回调：当倒计时归零的瞬间触发（用于播放提示音或震动）
  final VoidCallback? onTimerComplete;

  FocusController({
    required int workSeconds, // 必须通过构造函数传入
    required int restSeconds,
    required int longRestSeconds,
    this.onTimerComplete,
  }) : _workDuration = workSeconds,
       _restDuration = restSeconds,
       _longRestDuration = longRestSeconds,
       _targetSeconds = workSeconds,
       _currentSeconds = workSeconds {
    // 初始显示正确的时长
    debugPrint(
      '[FocusController] 构造函数调用: workSeconds=$workSeconds (${workSeconds ~/ 60}分钟), restSeconds=$restSeconds, longRestSeconds=$longRestSeconds (${longRestSeconds ~/ 60}分钟)',
    );
    debugPrint(
      '[FocusController] _workDuration 初始化为: $_workDuration (${_workDuration ~/ 60}分钟)',
    );
    // 异步初始化：当前会话循环计数
    _initializeCycleCount();
  }

  /// 初始化循环计数（内存态）
  Future<void> _initializeCycleCount() async {
    if (_isInitialized) return;
    _persistedCycleCount = 0;
    _currentCycleStep = 0; // 每次启动时重置当前会话的循环步骤
    _isInitialized = true;
    debugPrint(
      '[FocusController] 循环计数初始化: 持久化计数=$_persistedCycleCount, 当前会话步骤=$_currentCycleStep',
    );
  }

  /// 处理工作完成后的循环状态更新
  /// 当工作完成时，进入下一步（休息或下一个工作）
  Future<void> _onWorkCompleted() async {
    await _initializeCycleCount(); // 确保已初始化

    // 保存番茄钟记录到数据库
    await _saveFocusSession();

    // 检查当前步骤是否为最后一个工作步骤（6）
    // 如果是，完成循环
    if (_currentCycleStep == 6) {
      // 完成一个完整循环：工作 -> 休息 -> 工作 -> 休息 -> 工作 -> 休息 -> 工作
      debugPrint('[FocusController] ✅ 完成一个完整循环！');

      // 更新循环计数（内存）
      _persistedCycleCount = _persistedCycleCount + 1;
      debugPrint('[FocusController] 循环计数已更新: $_persistedCycleCount');

      // 重置当前会话的循环步骤
      _currentCycleStep = 0;
    } else {
      // 继续循环，进入下一步（休息）
      _currentCycleStep++;
      debugPrint('[FocusController] 工作完成，进入循环步骤 $_currentCycleStep (休息)');
    }
  }

  /// 保存番茄钟会话到数据库
  Future<void> _saveFocusSession() async {
    if (_sessionStartTime == null) return;

    final endTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = endTime - _sessionStartTime!;

    // 从 focusSessionState 获取关联的 taskId
    final taskId = focusSessionState.linkedTaskId;

    try {
      await db.into(db.focusSessions).insert(
        FocusSessionsCompanion(
          id: drift.Value(const Uuid().v4()),
          taskId: drift.Value(taskId), // 关联任务
          startTime: drift.Value(_sessionStartTime!),
          endTime: drift.Value(endTime),
          durationSeconds: drift.Value(duration),
          type: const drift.Value('work'),
          status: const drift.Value('completed'),
          // focusQuality 和 reviewNote 为 null，等待用户在日记页面填写
        ),
      );
      debugPrint('[FocusController] ✅ 番茄钟记录已保存: ${duration ~/ 60}分钟, taskId=$taskId');
    } catch (e) {
      debugPrint('[FocusController] ❌ 保存番茄钟记录失败: $e');
    }

    _sessionStartTime = null;
  }

  /// 处理休息完成后的循环状态更新
  /// 当休息完成时，进入下一步（工作）
  Future<void> _onRestCompleted() async {
    await _initializeCycleCount(); // 确保已初始化

    // 检查当前步骤是否为奇数（休息步骤：1, 3, 5）
    // 休息完成后，进入下一个工作步骤
    if (_currentCycleStep < 6) {
      _currentCycleStep++;
      debugPrint('[FocusController] 休息完成，进入循环步骤 $_currentCycleStep (工作)');
    } else {
      // 不应该到达这里，因为休息步骤最大是5
      debugPrint('[FocusController] ⚠️ 警告：休息完成时步骤异常: $_currentCycleStep');
    }
  }

  // Getters
  FocusStatus get status => _status;
  int get workDuration => _workDuration;
  int get restDuration => _restDuration;
  int get longRestDuration => _longRestDuration;

  /// 获取当前在第几步 (0-7)，用于显示进度
  /// 0=工作1, 1=短休1, 2=工作2, 3=短休2, 4=工作3, 5=短休3, 6=工作4, 7=长休
  /// 确保 FocusStatus 和 PomodoroStage 在每一轮循环中正确关联：
  /// - 工作状态（idle/running/extending）→ 偶数步骤（0, 2, 4, 6）→ PomodoroStage.work
  /// - 短休息状态（restIdle/restRunning/restExtending）→ 奇数步骤（1, 3, 5）→ PomodoroStage.shortRest
  /// - 长休息状态（longRestIdle/longRestRunning/longRestExtending）→ 步骤7 → PomodoroStage.longRest
  int get currentRoundIndex {
    // 如果当前处于长休息状态（空闲、运行中或超时），显示步骤7
    if (_status == FocusStatus.longRestIdle ||
        _status == FocusStatus.longRestRunning ||
        _status == FocusStatus.longRestExtending) {
      return 7;
    }

    // 根据当前状态确定正确的索引
    // 工作状态（idle, running, extending）对应偶数步骤：0, 2, 4, 6
    // 短休息状态（restIdle, restRunning, restExtending）对应奇数步骤：1, 3, 5

    if (_status == FocusStatus.idle ||
        _status == FocusStatus.running ||
        _status == FocusStatus.extending) {
      // 工作状态：确保返回偶数步骤（0, 2, 4, 6）
      // _currentCycleStep 在状态转换时已经正确更新
      // 如果 _currentCycleStep 是偶数，直接返回；如果是奇数，说明状态和步骤不匹配，需要修正
      int step = _currentCycleStep;
      if (step % 2 != 0) {
        // 如果步骤是奇数但状态是工作，说明刚完成休息，应该显示下一个工作步骤
        step = step + 1;
        debugPrint('[FocusController] ⚠️ 状态和步骤不匹配：工作状态但步骤是奇数，已修正为 $step');
      }
      return step.clamp(0, 6);
    }

    if (_status == FocusStatus.restIdle ||
        _status == FocusStatus.restRunning ||
        _status == FocusStatus.restExtending) {
      // 短休息状态：确保返回奇数步骤（1, 3, 5）
      // _currentCycleStep 在状态转换时已经正确更新
      // 如果 _currentCycleStep 是奇数，直接返回；如果是偶数，说明状态和步骤不匹配，需要修正
      int step = _currentCycleStep;
      if (step % 2 == 0) {
        // 如果步骤是偶数但状态是休息，说明刚完成工作，应该显示休息步骤
        step = step + 1;
        debugPrint('[FocusController] ⚠️ 状态和步骤不匹配：休息状态但步骤是偶数，已修正为 $step');
      }
      return step.clamp(1, 5);
    }

    // 默认情况：根据循环步骤返回
    debugPrint(
      '[FocusController] ⚠️ 未匹配的状态：$_status，使用默认步骤 $_currentCycleStep',
    );
    return _currentCycleStep.clamp(0, 7);
  }

  /// 在空闲状态下手动切换到指定阶段（0-7）
  /// 0/2/4/6 -> 工作 idle，1/3/5 -> 短休 idle，7 -> 长休 idle
  void selectStageByIndex(int index) {
    // 仅在非运行状态下允许切换
    if (isActive) {
      debugPrint('[FocusController] selectStageByIndex: 当前正在运行，忽略切换');
      return;
    }

    final clamped = index.clamp(0, 7);
    if (clamped == 7) {
      _status = FocusStatus.longRestIdle;
      _currentSeconds = _longRestDuration;
      _targetSeconds = _longRestDuration;
      // 记录为完成4次工作后的长休阶段
      _currentCycleStep = 6;
      debugPrint('[FocusController] 手动切换到长休息阶段 (index=7)');
    } else if (clamped % 2 == 0) {
      _status = FocusStatus.idle;
      _currentSeconds = _workDuration;
      _targetSeconds = _workDuration;
      _currentCycleStep = clamped;
      debugPrint('[FocusController] 手动切换到工作阶段 (index=$clamped)');
    } else {
      _status = FocusStatus.restIdle;
      _currentSeconds = _restDuration;
      _targetSeconds = _restDuration;
      _currentCycleStep = clamped;
      debugPrint('[FocusController] 手动切换到短休阶段 (index=$clamped)');
    }

    notifyListeners();
  }

  // 判断当前是否处于某种"运行"状态（包含正计时）
  bool get isActive =>
      _status != FocusStatus.idle &&
      _status != FocusStatus.restIdle &&
      _status != FocusStatus.longRestIdle;

  // 判断是否处于休息状态（包括普通休息和长休息，用于显示暖色渐变）
  bool get isResting =>
      _status == FocusStatus.restIdle ||
      _status == FocusStatus.restRunning ||
      _status == FocusStatus.restExtending ||
      _status == FocusStatus.longRestIdle ||
      _status == FocusStatus.longRestRunning ||
      _status == FocusStatus.longRestExtending;

  // 进度条逻辑：0.0 -> 1.0
  double get progress {
    if (_targetSeconds == 0) return 0;

    // 如果处于 Extending 状态（超时），进度条保持填满 (1.0)
    // 表示"任务已完成，且在继续"
    if (_currentSeconds <= 0) return 1.0;

    return 1.0 - (_currentSeconds / _targetSeconds);
  }

  // 时间字符串逻辑
  String get timeString {
    // 如果小于等于0，说明在正计时，取绝对值并添加 "+" 前缀
    bool isExtending = _currentSeconds <= 0;
    int absSeconds = _currentSeconds.abs();

    final minutes = (absSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (absSeconds % 60).toString().padLeft(2, '0');

    return "${isExtending ? '+' : ''}$minutes:$seconds";
  }

  // 提供一个方法，供设置页修改时长后调用
  void updateSettings({
    int? newWorkSeconds,
    int? newRestSeconds,
    int? newLongRestSeconds,
  }) {
    debugPrint(
      '[FocusController] updateSettings 调用前: _workDuration=$_workDuration (${_workDuration ~/ 60}分钟), _restDuration=$_restDuration, _longRestDuration=$_longRestDuration (${_longRestDuration ~/ 60}分钟)',
    );
    if (newWorkSeconds != null) {
      debugPrint(
        '[FocusController] 更新 _workDuration: $_workDuration -> $newWorkSeconds (${newWorkSeconds ~/ 60}分钟)',
      );
      _workDuration = newWorkSeconds;
    }
    if (newRestSeconds != null) {
      debugPrint(
        '[FocusController] 更新 _restDuration: $_restDuration -> $newRestSeconds',
      );
      _restDuration = newRestSeconds;
    }
    if (newLongRestSeconds != null) {
      debugPrint(
        '[FocusController] 更新 _longRestDuration: $_longRestDuration -> $newLongRestSeconds (${newLongRestSeconds ~/ 60}分钟)',
      );
      _longRestDuration = newLongRestSeconds;
    }
    debugPrint(
      '[FocusController] updateSettings 调用后: _workDuration=$_workDuration (${_workDuration ~/ 60}分钟), _restDuration=$_restDuration, _longRestDuration=$_longRestDuration (${_longRestDuration ~/ 60}分钟)',
    );

    // 如果当前是 Idle 状态，立即刷新显示的时间
    if (_status == FocusStatus.idle) {
      _targetSeconds = _workDuration;
      _currentSeconds = _workDuration;
      notifyListeners();
    }
    // 如果当前是 RestIdle 状态，刷新休息时间
    if (_status == FocusStatus.restIdle) {
      _targetSeconds = _restDuration;
      _currentSeconds = _restDuration;
      notifyListeners();
    }
    // 如果当前是 LongRestIdle 状态，刷新长休息时间
    if (_status == FocusStatus.longRestIdle) {
      _targetSeconds = _longRestDuration;
      _currentSeconds = _longRestDuration;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------------
  // 动作方法
  // ----------------------------------------------------------------

  // 开始工作 (Work) - 现在使用 _workDuration 变量
  void startWork() {
    debugPrint('[FocusController] ⚠️ startWork() 被调用');
    debugPrint(
      '[FocusController] 当前 _workDuration = $_workDuration (${_workDuration ~/ 60}分钟)',
    );
    debugPrint('[FocusController] 当前 _currentSeconds = $_currentSeconds');
    debugPrint('[FocusController] 当前 _targetSeconds = $_targetSeconds');
    debugPrint('[FocusController] 当前状态 = $_status');
    debugPrint(
      '[FocusController] 即将使用 _workDuration=$_workDuration (${_workDuration ~/ 60}分钟) 开始计时',
    );
    // 记录开始时间
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _startTimer(FocusStatus.running, _workDuration);
  }

  // 开始休息 (Rest) - 现在使用 _restDuration 变量
  void startRest() {
    _startTimer(FocusStatus.restRunning, _restDuration);
  }

  // 开始长休息 (Long Rest) - 使用 _longRestDuration 变量
  void startLongRest() {
    debugPrint('[FocusController] startLongRest() 被调用');
    debugPrint(
      '[FocusController] 当前 _longRestDuration = $_longRestDuration (${_longRestDuration ~/ 60}分钟)',
    );
    _startTimer(FocusStatus.longRestRunning, _longRestDuration);
  }

  // 统一的内部启动逻辑
  void _startTimer(FocusStatus startStatus, int duration) {
    debugPrint(
      '[FocusController] _startTimer() 被调用: startStatus=$startStatus, duration=$duration (${duration ~/ 60}分钟)',
    );
    debugPrint(
      '[FocusController] 调用前: _workDuration=$_workDuration, _restDuration=$_restDuration',
    );
    _stopTimer(); // 清除旧定时器
    _status = startStatus;
    _targetSeconds = duration;
    _currentSeconds = duration;
    debugPrint(
      '[FocusController] 调用后: _targetSeconds=$_targetSeconds, _currentSeconds=$_currentSeconds',
    );
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentSeconds--; // 无论是倒计时还是正计时，数值都持续减小 (10 -> 0 -> -1 -> -2)

      // 检查是否刚刚跨过 0 点
      if (_currentSeconds == 0) {
        _handleZeroCrossing();
      }

      notifyListeners();
    });
  }

  // 处理 0 点跨越逻辑（预结束方法）
  void _handleZeroCrossing() {
    // 1. 触发回调（播放声音等）
    onTimerComplete?.call();

    // 2. 切换状态到对应的 Extending（继续正计时）
    if (_status == FocusStatus.running) {
      _status = FocusStatus.extending;
      debugPrint('[FocusController] 工作倒计时结束，进入 extending 状态（继续正计时）');
    } else if (_status == FocusStatus.restRunning) {
      _status = FocusStatus.restExtending;
      debugPrint('[FocusController] 休息倒计时结束，进入 restExtending 状态（继续正计时）');
    } else if (_status == FocusStatus.longRestRunning) {
      _status = FocusStatus.longRestExtending;
      debugPrint('[FocusController] 长休息倒计时结束，进入 longRestExtending 状态（继续正计时）');
    }
    // 注意：定时器不停止，继续运行
  }

  // ----------------------------------------------------------------
  // 停止/结束逻辑 (响应双击)
  // ----------------------------------------------------------------

  // 停止工作模式
  void stopWork() {
    _stopTimer();

    // 如果是在 extending 状态（工作超时正计时），双击后进入 restIdle 或 longRestIdle
    if (_status == FocusStatus.extending) {
      // 先检查当前步骤，判断是否应该触发长休息
      // 如果是步骤6，完成这个工作后就完成了一个完整循环
      bool willCompleteCycle = _currentCycleStep == 6;

      if (willCompleteCycle) {
        // 完成一个完整循环，应该进入长休息
        _status = FocusStatus.longRestIdle;
        _currentSeconds = _longRestDuration;
        _targetSeconds = _longRestDuration;
        debugPrint('[FocusController] 工作完成，触发长休息');

        // 异步更新持久化计数（不阻塞 UI）
        _onWorkCompleted();
      } else {
        // 继续普通循环，进入休息
        _status = FocusStatus.restIdle;
        _currentSeconds = _restDuration;
        _targetSeconds = _restDuration;
        debugPrint('[FocusController] 工作超时状态结束，进入 restIdle');

        // 异步更新循环状态（不阻塞 UI）
        _onWorkCompleted();
      }
    } else {
      // 其他情况（running 状态），回到工作空闲（未完成，不更新循环状态）
      _status = FocusStatus.idle;
      _currentSeconds = _workDuration;
      _targetSeconds = _workDuration;
      debugPrint('[FocusController] 工作状态结束，回到 idle');
    }
    notifyListeners();
  }

  // 停止休息模式 (包含你要求的逻辑分支)
  void stopRest() {
    _stopTimer();

    // 如果是在 restExtending 状态（休息超时正计时），双击后进入 idle（工作空闲）
    if (_status == FocusStatus.restExtending) {
      // 休息完成，更新循环状态
      _onRestCompleted();

      _status = FocusStatus.idle;
      _currentSeconds = _workDuration;
      _targetSeconds = _workDuration;
      debugPrint('[FocusController] 休息超时状态结束，进入 idle（工作空闲）');
    } else if (_currentSeconds > 0) {
      // 如果 _currentSeconds > 0，说明还没休息完 -> 回到休息空闲 (RestIdle)
      // 未完成，不更新循环状态
      _status = FocusStatus.restIdle;
      _currentSeconds = _restDuration;
      _targetSeconds = _restDuration;
      debugPrint('[FocusController] 休息状态结束，回到 restIdle');
    } else {
      // 其他情况（倒计时结束但未进入 extending），休息完成，更新循环状态
      _onRestCompleted();

      _status = FocusStatus.idle;
      _currentSeconds = _workDuration;
      _targetSeconds = _workDuration;
      debugPrint('[FocusController] 休息状态结束，回到 idle');
    }

    notifyListeners();
  }

  // 停止长休息模式
  void stopLongRest() {
    _stopTimer();

    // 如果是在 longRestExtending 状态（长休息超时正计时），双击后进入 idle（工作空闲）
    if (_status == FocusStatus.longRestExtending) {
      // 长休息完成，重置循环计数（因为已经完成了一个完整循环并进行了长休息）
      _resetCycleAfterLongRest();

      _status = FocusStatus.idle;
      _currentSeconds = _workDuration;
      _targetSeconds = _workDuration;
      debugPrint('[FocusController] 长休息超时状态结束，进入 idle（工作空闲）');
    } else if (_currentSeconds > 0) {
      // 如果 _currentSeconds > 0，说明还没休息完 -> 回到长休息空闲 (LongRestIdle)
      _status = FocusStatus.longRestIdle;
      _currentSeconds = _longRestDuration;
      _targetSeconds = _longRestDuration;
      debugPrint('[FocusController] 长休息状态结束，回到 longRestIdle');
    } else {
      // 其他情况（倒计时结束），长休息完成，重置循环计数
      _resetCycleAfterLongRest();

      _status = FocusStatus.idle;
      _currentSeconds = _workDuration;
      _targetSeconds = _workDuration;
      debugPrint('[FocusController] 长休息状态结束，回到 idle');
    }

    notifyListeners();
  }

  /// 长休息完成后重置循环计数
  Future<void> _resetCycleAfterLongRest() async {
    await _initializeCycleCount(); // 确保已初始化
    _persistedCycleCount = 0;
    _currentCycleStep = 0;
    debugPrint('[FocusController] 长休息完成，循环计数已重置');

    // 清除 Objective 关联（导入在文件顶部）
    // 注意：需要在文件顶部添加: import '../../main.dart';
    try {
      // 使用 dynamic import 避免循环依赖
      final sessionState = focusSessionState;
      sessionState.clearLink();
    } catch (e) {
      debugPrint('[FocusController] 清除关联失败: $e');
    }
  }

  /// 重置计时器到初始状态
  void reset() {
    _stopTimer();
    _status = FocusStatus.idle;
    _currentSeconds = _workDuration;
    _targetSeconds = _workDuration;
    _currentCycleStep = 0;
    debugPrint('[FocusController] 已重置计时器');
    notifyListeners();
  }

  // 内部辅助：销毁定时器
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
