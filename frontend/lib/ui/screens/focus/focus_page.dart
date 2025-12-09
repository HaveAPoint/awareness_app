import 'package:flutter/material.dart';
import '../interceptor/interceptor_overlay.dart';
import '../../../main.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background / Timer (Placeholder)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "25:00",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 80,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                const SizedBox(height: 20),
                const Text("保持专注", style: TextStyle(letterSpacing: 4)),
              ],
            ),
          ),

          // Catch Thought Button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _showInterceptor(context),
                icon: const Icon(Icons.psychology),
                label: const Text("捕捉念头"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInterceptor(BuildContext context) async {
    // Fetch active thoughts to slice
    final thoughts = await db.getAllActiveThoughts();

    if (context.mounted) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Interceptor",
        barrierColor: Colors.black54,
        pageBuilder: (context, anim1, anim2) {
          return InterceptorOverlay(
            thoughts: thoughts,
            onDefuse: (id) async {
              await db.defuseThought(id);
            },
          );
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return FadeTransition(opacity: anim1, child: child);
        },
      );
    }
  }
}
