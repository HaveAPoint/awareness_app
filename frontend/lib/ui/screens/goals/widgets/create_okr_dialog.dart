import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateOkrDialog extends StatefulWidget {
  final Function(
    String title,
    String? description,
    DateTime deadline,
    List<Map<String, dynamic>> keyResults,
  )
  onSave;

  const CreateOkrDialog({super.key, required this.onSave});

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
    _deadline = DateTime.now().add(const Duration(days: 90));
    _addKrRow(); // Start with one empty KR
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

  void _removeKrRow(int index) {
    if (_krRows.length <= 1) return; // Keep at least one
    setState(() {
      final row = _krRows.removeAt(index);
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
              'title': row.titleController.text,
              'target': double.tryParse(row.targetController.text) ?? 0.0,
              'unit': row.unitController.text,
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
              const Text(
                '新建目标',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _handleSave,
                child: const Text(
                  '保存',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
  final titleController = TextEditingController();
  final targetController = TextEditingController();
  final unitController = TextEditingController();

  void dispose() {
    titleController.dispose();
    targetController.dispose();
    unitController.dispose();
  }
}
