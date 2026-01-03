import 'package:flutter/foundation.dart';

/// 全局番茄钟会话状态管理器
/// 管理 Objective / KeyResult ↔ Focus Session 的关联关系
class FocusSessionState extends ChangeNotifier {
  String? _linkedObjectiveId;
  String? _linkedObjectiveTitle;
  String? _linkedKeyResultId;
  String? _linkedKeyResultTitle;

  String? get linkedObjectiveId => _linkedObjectiveId;
  String? get linkedObjectiveTitle => _linkedObjectiveTitle;
  String? get linkedKeyResultId => _linkedKeyResultId;
  String? get linkedKeyResultTitle => _linkedKeyResultTitle;

  bool get hasLink => _linkedObjectiveId != null || _linkedKeyResultId != null;
  bool get hasKeyResultLink => _linkedKeyResultId != null;

  /// 关联一个目标
  void linkObjective(String objectiveId, String objectiveTitle) {
    _linkedObjectiveId = objectiveId;
    _linkedObjectiveTitle = objectiveTitle;
    _linkedKeyResultId = null;
    _linkedKeyResultTitle = null;
    debugPrint(
      '[FocusSessionState] 已关联 Objective: $objectiveTitle (ID: $objectiveId)',
    );
    notifyListeners();
  }

  /// 关联一个 Key Result
  void linkKeyResult({
    required String objectiveId,
    required String objectiveTitle,
    required String keyResultId,
    required String keyResultTitle,
  }) {
    _linkedObjectiveId = objectiveId;
    _linkedObjectiveTitle = objectiveTitle;
    _linkedKeyResultId = keyResultId;
    _linkedKeyResultTitle = keyResultTitle;
    debugPrint(
      '[FocusSessionState] 已关联 KR: $keyResultTitle (ID: $keyResultId) -> Objective: $objectiveTitle',
    );
    notifyListeners();
  }

  /// 清除关联
  void clearLink() {
    if (_linkedObjectiveId == null && _linkedKeyResultId == null) return;
    debugPrint(
      '[FocusSessionState] 清除关联: $_linkedObjectiveTitle / $_linkedKeyResultTitle',
    );
    _linkedObjectiveId = null;
    _linkedObjectiveTitle = null;
    _linkedKeyResultId = null;
    _linkedKeyResultTitle = null;
    notifyListeners();
  }
}
