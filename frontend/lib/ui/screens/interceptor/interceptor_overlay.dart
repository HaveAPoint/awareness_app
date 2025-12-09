import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../common/blade/blade_painter.dart';
import '../../common/effects/particle_system.dart';
import '../../../logic/interceptor/game_controller.dart';
import '../../../data/database/database.dart';

class InterceptorOverlay extends StatefulWidget {
  final List<Thought> thoughts;
  final Function(String id) onDefuse;

  const InterceptorOverlay({
    super.key,
    required this.thoughts,
    required this.onDefuse,
  });

  @override
  State<InterceptorOverlay> createState() => _InterceptorOverlayState();
}

class _InterceptorOverlayState extends State<InterceptorOverlay>
    with SingleTickerProviderStateMixin {
  late GameController _controller;
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.thoughts = widget.thoughts;
    _controller.onDefuse = widget.onDefuse;

    _ticker = createTicker((elapsed) {
      setState(() {
        final size = MediaQuery.of(context).size;
        _controller.update(size.width, size.height);
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(
        alpha: 0.85,
      ), // Semi-transparent background
      body: GestureDetector(
        onPanStart: (details) {
          _controller.clearBlade();
          _controller.addBladePoint(details.localPosition);
        },
        onPanUpdate: (details) {
          _controller.addBladePoint(details.localPosition);
        },
        onPanEnd: (details) => _controller.clearBlade(),
        child: Stack(
          children: [
            // Layer 1: Flying Items
            ..._controller.activeItems.map(
              (item) => Positioned(
                left: item.x - 75,
                top: item.y - 40,
                child: Transform.rotate(
                  angle: item.rotation,
                  child: _buildItemWidget(item),
                ),
              ),
            ),

            // Layer 2: Split Pieces
            ..._controller.splitPieces.map(
              (piece) => Positioned(
                left: piece.x - 75,
                top: piece.y - 40,
                child: Transform.rotate(
                  angle: piece.rotation,
                  child: Opacity(opacity: piece.opacity, child: piece.child),
                ),
              ),
            ),

            // Layer 3: Blade
            CustomPaint(
              painter: BladePainter(points: _controller.bladePoints),
              child: Container(),
            ),

            // Layer 4: Particles
            CustomPaint(
              painter: ParticlePainter(particles: _controller.particles),
              child: Container(),
            ),

            // Close Button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Title/Instruction
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Text(
                  "划动切碎杂念",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build widget (duplicated logic from controller for now, or we can make controller return data only)
  // Ideally controller shouldn't know about Widgets, but for MVP speed we kept it there.
  // But here we need to render it.
  // Wait, the controller's split pieces already contain the Widget child.
  // But activeItems don't.
  Widget _buildItemWidget(FlyingItem item) {
    bool isTrouble = item.type == ItemType.trouble;
    return Container(
      width: 150,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTrouble ? Colors.white30 : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          item.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isTrouble ? Colors.white70 : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
