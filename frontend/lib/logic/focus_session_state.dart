import 'package:flutter/foundation.dart';

/// 全局番茄钟会话状态管理器
/// 管理 Objective ↔ Focus Session 的关联关系
class FocusSessionState extends ChangeNotifier {
  String? _linkedObjectiveId;
  String? _linkedObjectiveTitle;

  String? get linkedObjectiveId => _linkedObjectiveId;
  String? get linkedObjectiveTitle => _linkedObjectiveTitle;

  bool get hasLink => _linkedObjectiveId != null;

  /// 关联一个目标
  void linkObjective(String objectiveId, String objectiveTitle) {
    _linkedObjectiveId = objectiveId;
    _linkedObjectiveTitle = objectiveTitle;
    debugPrint(
      '[FocusSessionState] 已关联 Objective: $objectiveTitle (ID: $objectiveId)',
    );
    notifyListeners();
  }

  /// 清除关联
  void clearLink() {
    if (_linkedObjectiveId == null) return;
    debugPrint(
      '[FocusSessionState] 清除关联: $_linkedObjectiveTitle (ID: $_linkedObjectiveId)',
    );
    _linkedObjectiveId = null;
    _linkedObjectiveTitle = null;
    notifyListeners();
  }
}
