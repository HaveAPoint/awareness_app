import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/goal_models.dart';

class CreateOkrDialog extends StatefulWidget {
  final Function(
    String title,
    String? description,
    DateTime deadline,
    List<Map<String, dynamic>> keyResults,
  )
  onSave;
  final VoidCallback? onDelete; // 删除回调（仅编辑模式）
  final ObjectiveModel? initialData; // null = 创建模式, 非null = 编辑模式

  const CreateOkrDialog({
    super.key,
    required this.onSave,
    this.onDelete,
    this.initialData,
  });

  @override
  State<CreateOkrDialog> createState() => _CreateOkrDialogState();
}

class _CreateOkrDialogState extends State<CreateOkrDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Default deadline: End of current quarter or next 30 days
  late DateTime _deadline;

  final List<_KeyResultFormRow> _krRows = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      // 编辑模式：预填充现有数据
      final obj = widget.initialData!;
      _titleController.text = obj.title;
      _descController.text = obj.description ?? '';
      _deadline = DateTime.fromMillisecondsSinceEpoch(obj.deadline * 1000);

      // 预填充 KRs（包含ID）
      for (final kr in obj.keyResults) {
        _krRows.add(_KeyResultFormRow(
          id: kr.id,
          initialTitle: kr.title,
          initialTarget: kr.targetVal.toString(),
          initialUnit: kr.unit ?? '',
        ));
      }
    } else {
      // 创建模式：默认配置
      _deadline = DateTime.now().add(const Duration(days: 90));
      _addKrRow(); // Start with one empty KR
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (var row in _krRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addKrRow() {
    setState(() {
      _krRows.add(_KeyResultFormRow());
    });
  }

  void _removeKrRow(int index) async {
    if (_krRows.length <= 1) return; // Keep at least one

    final row = _krRows[index];

    // 如果是编辑模式且KR有ID（即已存在的KR），需要确认
    if (widget.initialData != null && row.id != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: const Text(
            '删除此关键结果后，其所有历史打卡数据也会被永久删除。\n\n确定要继续吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        ),
      );

      if (confirmed != true) return; // 用户取消
    }

    setState(() {
      _krRows.removeAt(index);
      row.dispose();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final krs = _krRows
          .map(
            (row) => {
              'id': row.id, // 传递ID（null表示新建）
              'title': row.titleController.text,
              'target': double.tryParse(row.targetController.text) ?? 0.0,
              'unit': row.unitController.text.isEmpty ? null : row.unitController.text,
            },
          )
          .toList();

      widget.onSave(
        _titleController.text,
        _descController.text.isEmpty ? null : _descController.text,
        _deadline,
        krs,
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text(
          '删除此目标后，其所有关键结果和历史数据都会被永久删除。\n\n确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.of(context).pop(); // 关闭编辑对话框
      widget.onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get full height if needed, but DraggableScrollableSheet is better for bottom sheets
    // For a simple Dialog, we can use Dialog or simple Container in BottomSheet
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialData == null ? '新建目标' : '编辑目标',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _handleSave,
                child: Text(
                  widget.initialData == null ? '保存' : '更新',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(),

          // Scrollable Form
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Objective Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '目标标题',
                        hintText: '你想达成什么目标？',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入标题';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: '描述（可选）',
                        hintText: '为什么这个目标很重要？',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Deadline Picker
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '截止日期',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat.yMMMd().format(_deadline),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      '关键结果',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dynamic KR List
                    ..._krRows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: row.titleController,
                                decoration: InputDecoration(
                                  labelText: '关键结果 ${index + 1}',
                                  hintText: '可衡量的结果',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '必填';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: row.targetController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '目标值',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return '必填';
                                  if (double.tryParse(value) == null)
                                    return '数字';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: row.unitController,
                                decoration: const InputDecoration(
                                  labelText: '单位',
                                  hintText: '%',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            if (_krRows.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeKrRow(index),
                              ),
                          ],
                        ),
                      );
                    }),

                    // Add KR Button
                    OutlinedButton.icon(
                      onPressed: _addKrRow,
                      icon: const Icon(Icons.add),
                      label: const Text('添加关键结果'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                    // 删除按钮（仅编辑模式）
                    if (widget.initialData != null && widget.onDelete != null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _handleDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('删除此目标'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyResultFormRow {
  final String? id; // 用于区分新建/更新（null=新建，非null=更新）
  final titleController = TextEditingController();
  final targetController = TextEditingController();
  final unitController = TextEditingController();

  _KeyResultFormRow({
    this.id,
    String? initialTitle,
    String? initialTarget,
    String? initialUnit,
  }) {
    if (initialTitle != null) titleController.text = initialTitle;
    if (initialTarget != null) targetController.text = initialTarget;
    if (initialUnit != null) unitController.text = initialUnit;
  }

  void dispose() {
    titleController.dispose();
    targetController.dispose();
    unitController.dispose();
  }
}
