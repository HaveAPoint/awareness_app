import 'package:flutter/material.dart';

class LaunchpadSection extends StatelessWidget {
  const LaunchpadSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.blue.shade100,
      child: const Center(child: Text('Launchpad: 意图发射台')),
    );
  }
}
