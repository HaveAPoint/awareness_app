import 'package:flutter/material.dart';
import '../task_entity.dart';

class GoalCard extends StatelessWidget {
  final TaskEntity task;
  final ValueChanged<bool?> onCheck;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.task,
    required this.onCheck,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: task.isCompleted,
                  activeColor: Colors.black,
                  shape: const CircleBorder(),
                  onChanged: onCheck,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
