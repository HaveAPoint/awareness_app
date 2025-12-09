import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../data/database/database.dart';
import '../../../main.dart'; // Access global db

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  late Future<List<Thought>> _thoughtsFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      // For journal, we might want to see all thoughts or just inbox?
      // Let's show Inbox for now as per requirements.
      _thoughtsFuture = db.getInboxThoughts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('念头收件箱')),
      body: FutureBuilder<List<Thought>>(
        future: _thoughtsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final thoughts = snapshot.data ?? [];
          if (thoughts.isEmpty) {
            return const Center(child: Text('收件箱是空的，保持觉知。'));
          }

          return ListView.builder(
            itemCount: thoughts.length,
            itemBuilder: (context, index) {
              final thought = thoughts[index];
              return ListTile(
                title: Text(thought.content),
                subtitle: Text(thought.createdAt.toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      // Mark as processed/defused or delete?
                      // For now, let's just "defuse" it to hide it from inbox
                      await db.defuseThought(thought.id);
                    _refreshList();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Quick add thought
          _showAddDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("记录念头"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "你在想什么？"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await db.insertThought(ThoughtsCompanion(
                  id: drift.Value(const Uuid().v4()),
                  content: drift.Value(controller.text),
                  category: const drift.Value('inbox'),
                ));
                _refreshList();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }
}
