import 'package:flutter/material.dart';
import 'task_entity.dart';
import 'widgets/goal_card.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final TextEditingController _inputController = TextEditingController();

  final List<TaskEntity> _tasks = [
    TaskEntity(id: '1', title: '配置开发环境', createdAt: DateTime.now()),
    TaskEntity(id: '2', title: '设计数据库 Schema', createdAt: DateTime.now()),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _tasks.insert(
        0,
        TaskEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: text,
          createdAt: DateTime.now(),
        ),
      );
    });

    _inputController.clear();
  }

  void _handleTaskCheck(String id, bool? value) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index == -1) return;

      final task = _tasks[index];
      final completedAt = value == true ? DateTime.now() : null;

      _tasks[index] = task.copyWith(
        isCompleted: value ?? false,
        completedAt: completedAt,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务清单')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: '输入任务...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addTask, child: const Text('添加')),
              ],
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? Center(
                    child: Text(
                      '还没有任务，先加一条吧',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return GoalCard(
                        task: task,
                        onCheck: (val) => _handleTaskCheck(task.id, val),
                        onTap: () {
                          debugPrint('Task clicked: ${task.createdAt}');
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
