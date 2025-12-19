import 'dart:math';
import 'package:flutter/material.dart';

// --- 粒子定义 ---
class Particle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  double life; // 1.0 (新) -> 0.0 (死)
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

// --- 粒子画笔 ---
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      if (p.life <= 0) continue;
      // 根据生命周期计算透明度
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

// --- 被切开的碎片定义 ---
class SplitPiece {
  final Widget child;
  double x;
  double y;
  double velocityX;
  double velocityY;
  double rotation;
  double rotationSpeed;
  double opacity;

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

// --- 补充工具：向量旋转（供刀光/碎片使用） ---
extension OffsetExtension on Offset {
  /// 将向量旋转 [angle] 弧度
  Offset rotate(double angle) {
    final double cosTheta = cos(angle);
    final double sinTheta = sin(angle);
    return Offset(dx * cosTheta - dy * sinTheta, dx * sinTheta + dy * cosTheta);
  }
}
