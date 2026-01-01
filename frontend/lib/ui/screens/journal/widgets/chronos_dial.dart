import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../data/database/database.dart';

/// 配色方案（基于 context.md）
class _DialColors {
  // 背景轨道
  static const Color trackBg = Color(0xFFEDEEF0); // 微妙灰白
  static const Color trackShadow = Color(0xFFD1D5DA); // 内阴影

  // 文字
  static const Color textPrimary = Color(0xFF2D3748); // 深灰主文本
  static const Color textSecondary = Color(0xFF718096); // 浅灰次文本

  // 当前时间指针
  static const Color cursor = Color(0xFF3182CE);

  // 目标色彩（语义化）
  static const Color objectiveAmber = Color(0xFFF6AD55); // 创作/心流
  static const Color objectivePurple = Color(0xFF9F7AEA); // 深度工作
  static const Color objectiveTeal = Color(0xFF4FD1C5); // 成长/健康
}

/// Chronos Dial - 时间分配圆盘
class ChronosDial extends StatelessWidget {
  final List<PomodoroSessionData> sessions;
  final double size;

  const ChronosDial({
    super.key,
    required this.sessions,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(30), // 为刻度标签留出空间
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            // 外部阴影，增加浮现感（柔和多层投影）
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                // 主投影
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(0, 6),
                ),
                // 次投影（更扩散）
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 40,
                  spreadRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _ChronosDialPainter(
                sessions: sessions,
                currentTime: now,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pomodoro 会话数据
class PomodoroSessionData {
  final DateTime startTime;
  final int durationMinutes;
  final Color color;

  PomodoroSessionData({
    required this.startTime,
    required this.durationMinutes,
    required this.color,
  });

  /// 从数据库 FocusSession 创建
  static PomodoroSessionData fromFocusSession(
    FocusSession session,
    Color color,
  ) {
    return PomodoroSessionData(
      startTime: DateTime.fromMillisecondsSinceEpoch(session.startTime * 1000),
      durationMinutes: session.durationSeconds ~/ 60,
      color: color,
    );
  }
}

/// 自定义绘制器
class _ChronosDialPainter extends CustomPainter {
  final List<PomodoroSessionData> sessions;
  final DateTime currentTime;

  // 时间窗口：00:00-24:00 (24小时)
  static const double startHour = 0.0;
  static const double endHour = 24.0;
  static const double totalHours = endHour - startHour;
  final int totalMinutes = (totalHours * 60).toInt();

  _ChronosDialPainter({
    required this.sessions,
    required this.currentTime,
  });

  // 辅助函数：时间转角度
  double _timeToAngle(DateTime time) {
    final dayStart = DateTime(time.year, time.month, time.day, startHour.toInt(), 0);
    int minutesFromStart = time.difference(dayStart).inMinutes;
    minutesFromStart = minutesFromStart.clamp(0, totalMinutes);
    return (minutesFromStart / totalMinutes) * 2 * math.pi;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 10;
    const strokeWidth = 28.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // -pi/2 让 05:00 出现在最上方
    const startAngleOffset = -math.pi / 2;

    // 1. 绘制背景轨道（内阴影效果）
    _drawBackgroundTrack(canvas, center, radius, strokeWidth);

    // 2. 绘制会话段（带渐变）
    _drawSessionSegments(canvas, rect, radius, strokeWidth, startAngleOffset);

    // 3. 绘制当前时间指针（发光效果）
    _drawCurrentTimeIndicator(canvas, center, radius, startAngleOffset);

    // 4. 绘制中心文字
    _drawCenterText(canvas, center);

    // 5. 绘制刻度文本
    _drawTickLabels(canvas, center, radius);
  }

  /// 绘制背景轨道（凹槽效果：多层内阴影）
  void _drawBackgroundTrack(Canvas canvas, Offset center, double radius, double strokeWidth) {
    // 第1层：最深的内阴影底色
    final bgDeepShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..color = const Color(0xFFBCC5D3); // 更深的阴影
    canvas.drawCircle(center, radius, bgDeepShadowPaint);

    // 第2层：中间过渡层
    final bgShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = _DialColors.trackShadow;
    canvas.drawCircle(center, radius, bgShadowPaint);

    // 第3层：亮色上层，露出边缘形成多层内阴影
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth - 3
      ..color = _DialColors.trackBg;
    canvas.drawCircle(center, radius, bgPaint);
  }

  /// 绘制会话段（带光泽渐变和间隙）
  void _drawSessionSegments(
    Canvas canvas,
    Rect rect,
    double radius,
    double strokeWidth,
    double startAngleOffset,
  ) {
    for (var i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      final startAngle = _timeToAngle(session.startTime) + startAngleOffset;

      // 计算弧段角度，留出微小间隙
      final rawSweepAngle = (session.durationMinutes / totalMinutes) * 2 * math.pi;
      final gapAngle = 0.01; // 约 0.57 度的间隙
      final sweepAngle = rawSweepAngle - gapAngle;

      // 使用渐变增加光泽感（从浅到深再到浅）
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          session.color.withOpacity(0.7), // 起点：较浅
          session.color, // 中间：实色（最亮）
          session.color.withOpacity(0.85), // 终点：稍浅
        ],
        stops: const [0.0, 0.5, 1.0],
        tileMode: TileMode.clamp,
      );

      final sessionPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth - 4
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle, false, sessionPaint);
    }
  }

  /// 绘制当前时间指针（发光效果）
  void _drawCurrentTimeIndicator(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngleOffset,
  ) {
    final currentAngle = _timeToAngle(currentTime) + startAngleOffset;

    // 发光外圈
    final cursorPaint = Paint()
      ..color = _DialColors.cursor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final cursorX = center.dx + radius * math.cos(currentAngle);
    final cursorY = center.dy + radius * math.sin(currentAngle);

    // 发光圆点
    canvas.drawCircle(Offset(cursorX, cursorY), 6, cursorPaint);

    // 中心白点，增加层次
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      3,
      Paint()..color = Colors.white,
    );
  }

  /// 绘制中心文字
  void _drawCenterText(Canvas canvas, Offset center) {
    // 时间（大、粗、深色）
    final timeSpan = TextSpan(
      text: "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}\n",
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: _DialColors.textPrimary,
        height: 1.1,
      ),
    );
    final timePainter = TextPainter(
      text: timeSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    timePainter.layout();

    // 标签（小、细、浅色）
    final labelSpan = TextSpan(
      text: "当前时间",
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _DialColors.textSecondary,
      ),
    );
    final labelPainter = TextPainter(
      text: labelSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();

    // 垂直居中绘制
    final totalHeight = timePainter.height + labelPainter.height;
    timePainter.paint(
      canvas,
      center - Offset(timePainter.width / 2, totalHeight / 2),
    );
    labelPainter.paint(
      canvas,
      center -
          Offset(labelPainter.width / 2,
              -timePainter.height / 2 + totalHeight / 2),
    );
  }

  /// 绘制刻度标签
  void _drawTickLabels(Canvas canvas, Offset center, double radius) {
    final labels = [
      {'hour': 0, 'text': '00:00'},
      {'hour': 6, 'text': '06:00'},
      {'hour': 12, 'text': '12:00'},
      {'hour': 18, 'text': '18:00'},
    ];

    for (final label in labels) {
      final hour = label['hour'] as int;
      final text = label['text'] as String;

      final tickTime = DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        hour,
        0,
      );
      final angle = _timeToAngle(tickTime) - math.pi / 2;

      final textRadius = radius + 30;
      final x = center.dx + textRadius * math.cos(angle);
      final y = center.dy + textRadius * math.sin(angle);

      final textSpan = TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _DialColors.textSecondary,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ChronosDialPainter oldDelegate) {
    return sessions != oldDelegate.sessions ||
        currentTime != oldDelegate.currentTime;
  }
}
