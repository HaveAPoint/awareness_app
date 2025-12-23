import 'package:flutter/material.dart';

class MirrorSection extends StatelessWidget {
  const MirrorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 10,
      itemBuilder: (context, index) => Card(
        child: ListTile(
          title: Text('Reflection #${index + 1}'),
          subtitle: const Text('这是一个示例条目'),
        ),
      ),
    );
  }
}
