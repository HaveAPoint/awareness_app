import 'dart:math';
import 'package:flutter/material.dart';

// 真正的“画家” —— V2 赛博朋克版
// 真正的“画家” —— V3 虚空裂隙版
class BladePainter extends CustomPainter {
  final List<Offset> points;

  BladePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // --- 1. 参数调优：凌厉感 ---
    // 之前是 20.0，现在改小，让它更细更锋利
    final double maxThickness = 12.0; 

    // --- 2. 颜色配置：从内到外 ---
    // 核心：纯黑 (虚空)
    final Color coreColor = Colors.black; 
    // 中层：深蓝/靛青 (能量实体)
    final Color midColor = Colors.blue.shade900; 
    // 外层：亮青 (发光边缘)
    final Color glowColor = Colors.cyanAccent.shade400;

    // --- 3. 生成路径 ---
    // 我们生成三个不同宽度的路径，层层叠加
    // 1.0 = 原宽度 (最宽)
    final Path outerPath = _generateSharpPath(points, maxThickness * 1.0); 
    // 0.7 = 中间层
    final Path midPath = _generateSharpPath(points, maxThickness * 0.7);   
    // 0.3 = 核心 (极细)
    final Path innerPath = _generateSharpPath(points, maxThickness * 0.35); 

    // --- 4. 绘制 (Painter's Algorithm: 先画的在底下) ---

    // Layer 1: 外发光 (浅蓝) - 负责辉光
    final Paint glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      // 较大的模糊，制造“光刃”的感觉
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    
    canvas.drawPath(outerPath, glowPaint);
    
    // 为了让边缘更锐利，再画一层不模糊的浅蓝细线垫底
    final Paint sharpGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, sharpGlowPaint);

    // Layer 2: 刀身 (深蓝) - 负责主体
    final Paint midPaint = Paint()
      ..color = midColor
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(midPath, midPaint);

    // Layer 3: 虚空核心 (黑色) - 负责“裂痕感”
    final Paint corePaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(innerPath, corePaint);
  }

  // --- 核心数学逻辑：生成更“凌厉”的菱形 ---
  Path _generateSharpPath(List<Offset> rawPoints, double maxThickness) {
    final Path path = Path();
    
    List<Offset> topPoints = [];
    List<Offset> bottomPoints = [];

    for (int i = 0; i < rawPoints.length - 1; i++) {
      Offset current = rawPoints[i];
      Offset next = rawPoints[i + 1];

      // 计算法向量
      Offset dir = next - current;
      // 避免除以0的错误
      if (dir.distance == 0) continue;
      
      Offset normal = Offset(-dir.dy, dir.dx) / dir.distance;

      // --- 关键修改：更尖锐的形状函数 ---
      double progress = i / rawPoints.length;
      
      // 原来是 sin(progress * pi)，那是圆润的梭形
      // 现在用 pow(sin(...), 2.5)，会让两头收缩得更快，看起来像针尖
      double shapeFactor = pow(sin(progress * pi), 2.0).toDouble();
      
      double currentWidth = shapeFactor * maxThickness;

      topPoints.add(current + normal * currentWidth);
      bottomPoints.add(current - normal * currentWidth);
    }

    if (topPoints.isEmpty) return path;

    // 组装路径
    path.moveTo(rawPoints[0].dx, rawPoints[0].dy);
    
    for (var p in topPoints) {
      path.lineTo(p.dx, p.dy);
    }
    
    path.lineTo(rawPoints.last.dx, rawPoints.last.dy);
    
    for (int i = bottomPoints.length - 1; i >= 0; i--) {
      path.lineTo(bottomPoints[i].dx, bottomPoints[i].dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant BladePainter oldDelegate) {
    return true;
  }
}
