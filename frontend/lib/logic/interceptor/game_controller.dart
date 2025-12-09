import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/common/effects/particle_system.dart';
import '../../data/database/database.dart'; // For Thought type

enum ItemType { trouble, affirmation }

class FlyingItem {
  String id;
  String text;
  ItemType type;
  double x;
  double y;
  double velocityX;
  double velocityY;
  double rotation;
  double rotationSpeed;
  Color color;

  FlyingItem({
    required this.id,
    required this.text,
    required this.type,
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.color,
  })  : rotation = (Random().nextDouble() - 0.5) * 0.35,
        rotationSpeed = (Random().nextDouble() - 0.5) * 0.01;
}

class GameController {
  // State
  List<FlyingItem> activeItems = [];
  List<Offset> bladePoints = [];
  List<Particle> particles = [];
  List<SplitPiece> splitPieces = [];

  // Config
  final Random _rng = Random();
  final double _gravity = 0.3;
  final int _spawnRate = 60;
  int _frameCounter = 0;
  
  // Data Source
  List<Thought> thoughts = [];
  final List<String> _affirmations = [
    "我是值得被爱的", "我已经很努力了", "允许自己休息",
    "失败不是终点", "我有能力改变", "今天也是棒棒的",
  ];

  // Callbacks
  Function(String uuid)? onDefuse;

  void update(double screenW, double screenH) {
    _frameCounter++;
    if (_frameCounter % _spawnRate == 0) {
      _spawnItem(screenW, screenH);
    }

    _updateFlyingItems(screenW, screenH);
    _updateSplitPieces(screenH);
    _updateParticles();

    if (bladePoints.isNotEmpty && _frameCounter % 2 == 0) {
      bladePoints.removeAt(0);
    }
  }

  void addBladePoint(Offset point) {
    bladePoints.add(point);
    if (bladePoints.length > 15) {
      bladePoints.removeAt(0);
    }
    _checkCollision(point);
  }

  void clearBlade() {
    bladePoints.clear();
  }

  void _spawnItem(double screenW, double screenH) {
    const double itemWidth = 150.0;
    const double safePadding = 20.0;
    final double minX = (itemWidth / 2) + safePadding;
    final double maxX = screenW - (itemWidth / 2) - safePadding;
    
    double spawnX;
    if (maxX > minX) {
      spawnX = _rng.nextDouble() * (maxX - minX) + minX;
    } else {
      spawnX = screenW / 2;
    }

    bool isTrouble = _rng.nextDouble() < 0.7;
    if (thoughts.isEmpty) isTrouble = false;

    String text; String id; Color color; ItemType type;
    if (isTrouble && thoughts.isNotEmpty) {
      final thought = thoughts[_rng.nextInt(thoughts.length)];
      text = thought.content;
      id = thought.id;
      color = Colors.grey[800]!;
      type = ItemType.trouble;
    } else {
      text = _affirmations[_rng.nextInt(_affirmations.length)];
      id = "affirmation_${_rng.nextInt(9999)}";
      color = Colors.amber[600]!;
      type = ItemType.affirmation;
    }
    
    activeItems.add(FlyingItem(
      id: id, text: text, type: type, x: spawnX, y: screenH + 50,
      velocityX: (_rng.nextDouble() - 0.5) * 4,
      velocityY: -13.0 - _rng.nextDouble() * 4,
      color: color,
    ));
  }

  void _updateFlyingItems(double screenW, double screenH) {
    const double itemHalfWidth = 75.0;
    const double wallPadding = 10.0;
    List<FlyingItem> toRemove = [];
    
    for (var item in activeItems) {
      item.x += item.velocityX;
      item.y += item.velocityY;
      item.velocityY += _gravity;
      item.rotation += item.rotationSpeed;
      
      const double maxRotation = 0.5;
      if (item.rotation > maxRotation) {
        item.rotation = maxRotation;
        item.rotationSpeed = -item.rotationSpeed.abs();
      } else if (item.rotation < -maxRotation) {
        item.rotation = -maxRotation;
        item.rotationSpeed = item.rotationSpeed.abs();
      }
      
      if (item.x < itemHalfWidth + wallPadding) {
        item.x = itemHalfWidth + wallPadding;
        item.velocityX = item.velocityX.abs() * 0.8;
      } else if (item.x > screenW - itemHalfWidth - wallPadding) {
        item.x = screenW - itemHalfWidth - wallPadding;
        item.velocityX = -item.velocityX.abs() * 0.8;
      }
      
      if (item.y > screenH + 100) toRemove.add(item);
    }
    activeItems.removeWhere((item) => toRemove.contains(item));
  }

  void _updateSplitPieces(double screenH) {
    List<SplitPiece> toRemove = [];
    for (var piece in splitPieces) {
      piece.x += piece.velocityX;
      piece.y += piece.velocityY;
      piece.velocityY += _gravity * 1.5;
      piece.rotation += piece.rotationSpeed;
      piece.opacity -= 0.02;

      if (piece.y > screenH + 100 || piece.opacity <= 0) {
        toRemove.add(piece);
      }
    }
    splitPieces.removeWhere((p) => toRemove.contains(p));
  }

  void _updateParticles() {
    List<Particle> toRemove = [];
    for (var p in particles) {
      p.x += p.velocityX;
      p.y += p.velocityY;
      p.velocityY += _gravity * 0.5;
      p.life -= 0.03;
      if (p.life <= 0) toRemove.add(p);
    }
    particles.removeWhere((p) => toRemove.contains(p));
  }

  void _checkCollision(Offset touchPoint) {
    const itemWidth = 150.0;
    const itemHeight = 80.0;
    Offset cutVector = Offset.zero;
    if (bladePoints.length >= 2) {
      cutVector = bladePoints.last - bladePoints[bladePoints.length - 2];
    }

    for (var item in List.of(activeItems)) {
      Rect rect = Rect.fromCenter(center: Offset(item.x, item.y), width: itemWidth, height: itemHeight);
      if (rect.contains(touchPoint)) {
        _spawnHitEffects(touchPoint, item.color, cutVector);

        if (item.type == ItemType.trouble) {
          _onSliceTrouble(item, cutVector);
        } else {
          // Affirmation sliced
          HapticFeedback.heavyImpact();
          // Callback or event could be triggered here
        }
      }
    }
  }

  void _spawnHitEffects(Offset pos, Color color, Offset cutVector) {
    for (int i = 0; i < 20; i++) {
      double speed = _rng.nextDouble() * 5 + 2;
      double angle = _rng.nextDouble() * 2 * pi;
      particles.add(Particle(
        x: pos.dx, y: pos.dy,
        velocityX: cos(angle) * speed,
        velocityY: sin(angle) * speed,
        color: color.withValues(alpha: 0.8),
        life: 1.0,
        size: _rng.nextDouble() * 6 + 2,
      ));
    }

    if (cutVector.distance > 0) {
      Offset direction = cutVector / cutVector.distance;
      for (int i = 0; i < 10; i++) {
        double speed = _rng.nextDouble() * 8 + 5;
        Offset v = direction.rotate((_rng.nextDouble() - 0.5) * 0.5) * speed;
        particles.add(Particle(
          x: pos.dx, y: pos.dy,
          velocityX: v.dx, velocityY: v.dy,
          color: Colors.white,
          life: 0.8,
          size: _rng.nextDouble() * 4 + 1,
        ));
      }
    }
  }

  void _onSliceTrouble(FlyingItem item, Offset cutVector) {
    HapticFeedback.lightImpact();
    activeItems.remove(item);
    
    // Notify DB
    onDefuse?.call(item.id);

    Offset normal = Offset(-cutVector.dy, cutVector.dx);
    if (normal.distance > 0) normal = normal / normal.distance;
    
    double splitSpeed = 5.0;

    // We need to create the widget for the split piece. 
    // Since GameController is logic-only, we might need a helper to build the widget 
    // or just store the data and let the UI build it.
    // For now, we'll store a placeholder or pass the widget builder in.
    // Actually, SplitPiece needs a Widget child. 
    // Let's make SplitPiece generic or handle the widget creation in UI.
    // Refactoring: SplitPiece in GameController will hold data, UI will render.
    // But existing SplitPiece holds a Widget. 
    // Let's assume we can create the widget here or pass a builder.
    // For simplicity, I'll replicate the widget building logic here or make it static.
    
    Widget itemWidget = _buildItemWidget(item, scale: 0.9);

    splitPieces.add(SplitPiece(
      child: itemWidget,
      x: item.x, y: item.y,
      velocityX: normal.dx * splitSpeed + item.velocityX,
      velocityY: normal.dy * splitSpeed + item.velocityY,
      rotation: item.rotation,
      rotationSpeed: _rng.nextDouble() * 0.2 + 0.1,
    ));

    splitPieces.add(SplitPiece(
      child: itemWidget,
      x: item.x, y: item.y,
      velocityX: -normal.dx * splitSpeed + item.velocityX,
      velocityY: -normal.dy * splitSpeed + item.velocityY,
      rotation: item.rotation,
      rotationSpeed: -(_rng.nextDouble() * 0.2 + 0.1),
    ));
  }

  Widget _buildItemWidget(FlyingItem item, {double scale = 1.0}) {
    bool isTrouble = item.type == ItemType.trouble;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 150, height: 80, alignment: Alignment.center,
        decoration: BoxDecoration(
          color: item.color, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isTrouble ? Colors.white30 : Colors.white, width: 2),
          boxShadow: [BoxShadow(color: item.color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)]
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(item.text, textAlign: TextAlign.center,
            style: TextStyle(color: isTrouble ? Colors.white70 : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}
