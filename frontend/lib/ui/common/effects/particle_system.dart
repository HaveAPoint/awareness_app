import 'dart:math';
import 'package:flutter/material.dart';

// --- 粒子定义 (火花/碎片) ---
class Particle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  double life; // 生命周期 (0.0 - 1.0)，1.0表示刚出生，0.0表示死亡
  Color color;
  double size;

  Particle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.life,
    required this.size,
  });
}

// --- 被切开的碎片定义 ---
class SplitPiece {
  Widget child; // 碎片的模样 (原来的 Widget)
  double x;
  double y;
  double velocityX;
  double velocityY;
  double rotation;
  double rotationSpeed;
  double opacity; // 透明度，用于渐隐消失

  SplitPiece({
    required this.child,
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
  }) : opacity = 1.0;
}

// --- 粒子画笔 ---
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      // 根据生命周期计算透明度
      final paint = Paint()..color = p.color.withValues(alpha: p.life);
      // 画圆形粒子
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, paint);
    }
  }
  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

// --- 补丁：给 Offset 类增加旋转功能 ---
extension OffsetExtension on Offset {
  /// 将向量旋转 [angle] 弧度
  Offset rotate(double angle) {
    double cosTheta = cos(angle);
    double sinTheta = sin(angle);
    return Offset(
      dx * cosTheta - dy * sinTheta,
      dx * sinTheta + dy * cosTheta,
    );
  }
}
