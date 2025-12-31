import 'package:flutter/material.dart';
import 'package:awareness_app/data/models/goal_models.dart';
import 'package:awareness_app/data/repositories/goal_repository.dart';
import 'package:awareness_app/main.dart';
import 'widgets/okr_card.dart';
import 'widgets/create_okr_dialog.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late final GoalRepository _repository;
  List<ObjectiveModel> _objectives = [];
  bool _isLoading = true;
  String _currentFilter =
      'active'; // 当前筛选状态：'all', 'active', 'completed', 'archived'

  @override
  void initState() {
    super.initState();
    _repository = GoalRepository(db);
    _loadObjectives();
  }

  Future<void> _loadObjectives() async {
    setState(() => _isLoading = true);
    try {
      final objectives = await _repository.getAllObjectives(
        statusFilter: _currentFilter,
      );
      setState(() {
        _objectives = objectives;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载目标失败: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FC,
      ), // Very light grey/blue background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            '我的目标',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: _currentFilter == 'active' ? Colors.black54 : Colors.blue,
            ),
            onSelected: (String value) {
              setState(() {
                _currentFilter = value;
              });
              _loadObjectives();
            },
            itemBuilder: (BuildContext context) => [
              _buildFilterMenuItem('all', '全部'),
              _buildFilterMenuItem('active', '进行中'),
              _buildFilterMenuItem('completed', '已结束'),
              _buildFilterMenuItem('archived', '已归档'),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(_objectives, '暂无目标'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("新建目标", style: TextStyle(color: Colors.white)),
        elevation: 4,
      ),
    );
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateOkrDialog(
        onSave: (title, description, deadline, krs) async {
          try {
            // 保存到数据库
            await _repository.createObjective(
              title: title,
              description: description,
              deadline: deadline.millisecondsSinceEpoch ~/ 1000,
              keyResults: krs.map((k) {
                return {
                  'title': k['title'],
                  'type': 'number',
                  'startVal': 0.0,
                  'targetVal': k['target'],
                  'currentVal': 0.0,
                  'unit': k['unit'],
                  'weight': 1.0,
                };
              }).toList(),
            );

            // 重新加载列表
            await _loadObjectives();

            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('目标创建成功')));
            }
          } catch (e) {
            debugPrint('创建目标失败: $e');
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('创建失败: $e')));
            }
          }
        },
      ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value, String label) {
    final isSelected = _currentFilter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ObjectiveModel> objectives, String emptyMessage) {
    if (objectives.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: objectives.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        return GoalCard(objective: objectives[index]);
      },
    );
  }
}
