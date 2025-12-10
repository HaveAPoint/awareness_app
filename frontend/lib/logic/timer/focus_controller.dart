import 'dart:async';
import 'package:flutter/material.dart';

enum TimerStatus { idle, running, paused }

class FocusController extends ChangeNotifier {
  static const int kDefaultFocusTime = 25 * 60; // 25分钟

  Timer? _timer;
  int _currentSeconds;
  int _initialSeconds;
  TimerStatus _status = TimerStatus.idle;
  final Future<void> Function(int seconds)? onTimerComplete;

  FocusController({int initialSeconds = kDefaultFocusTime})
    : _currentSeconds = initialSeconds,
      _initialSeconds = initialSeconds,
      onTimerComplete = null;

  FocusController.withCallback({
    int initialSeconds = kDefaultFocusTime,
    this.onTimerComplete,
  }) : _currentSeconds = initialSeconds,
       _initialSeconds = initialSeconds;

  // Getters
  int get currentSeconds => _currentSeconds;
  TimerStatus get status => _status;
  // 进度 0.0 -> 1.0
  double get progress =>
      _initialSeconds == 0 ? 0 : 1.0 - (_currentSeconds / _initialSeconds);

  String get timeString {
    final minutes = (_currentSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_currentSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void startFocus() {
    if (_status == TimerStatus.running) return;
    _status = TimerStatus.running;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 0) {
        _currentSeconds--;
        notifyListeners();
      } else {
        _finishFocus();
      }
    });
  }

  void pauseFocus() {
    _timer?.cancel();
    _status = TimerStatus.paused;
    notifyListeners();
  }

  void stopFocus() {
    _timer?.cancel();
    _currentSeconds = _initialSeconds;
    _status = TimerStatus.idle;
    notifyListeners();
  }

  void setDuration(Duration duration) {
    _timer?.cancel();
    _initialSeconds = duration.inSeconds;
    _currentSeconds = _initialSeconds;
    _status = TimerStatus.idle;
    notifyListeners();
  }

  void _finishFocus() {
    _timer?.cancel();
    _status = TimerStatus.idle;
    _currentSeconds = _initialSeconds;
    onTimerComplete?.call(_initialSeconds);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
