/// DotLabel 组件使用示例
///
/// 本文件展示了 DotLabel 组件的各种使用方式
/// 可在项目中参考这些示例来使用点前缀标签

import 'package:flutter/material.dart';
import 'package:awareness_app/ui/common/widgets/dot_label.dart';

class DotLabelExamples extends StatelessWidget {
  const DotLabelExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DotLabel 使用示例')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 示例 1: 基础 Objective 标签 ===
            const Text(
              '1. 基础 Objective 标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DotLabel.objective(context),
            const SizedBox(height: 24),

            // === 示例 2: 自定义文本的 Objective 标签 ===
            const Text(
              '2. 自定义文本的 Objective 标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DotLabel.objective(context, text: '深度工作'),
            const SizedBox(height: 24),

            // === 示例 3: 基础 Key Result 标签 ===
            const Text(
              '3. 基础 Key Result 标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DotLabel.keyResult(context),
            const SizedBox(height: 24),

            // === 示例 4: 自定义文本的 Key Result 标签 ===
            const Text(
              '4. 自定义文本的 Key Result 标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DotLabel.keyResult(context, text: '完成 10 个番茄钟'),
            const SizedBox(height: 24),

            // === 示例 5: 并排显示 OBJ 和 KR ===
            const Text(
              '5. 并排显示 OBJ 和 KR 标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                DotLabel.objective(context, text: '提升编程能力'),
                const SizedBox(width: 16),
                DotLabel.keyResult(context, text: '完成 5 个项目'),
              ],
            ),
            const SizedBox(height: 24),

            // === 示例 6: 列表中使用 ===
            const Text(
              '6. 在列表中使用标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListItem(
                  context,
                  label: DotLabel.objective(context, text: '健康生活'),
                  description: '每日冥想 30 分钟',
                ),
                const SizedBox(height: 8),
                _buildListItem(
                  context,
                  label: DotLabel.keyResult(context, text: '坚持 21 天'),
                  description: '建立习惯周期',
                ),
                const SizedBox(height: 8),
                _buildListItem(
                  context,
                  label: DotLabel.objective(context, text: '学习新技能'),
                  description: 'Flutter 高级进阶',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // === 示例 7: 自定义颜色 ===
            const Text(
              '7. 自定义颜色的标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                DotLabel.objective(
                  context,
                  text: '创作',
                  dotColor: const Color(0xFFF6AD55), // 琥珀金
                ),
                DotLabel.objective(
                  context,
                  text: '深度工作',
                  dotColor: const Color(0xFF9F7AEA), // 深紫色
                ),
                DotLabel.objective(
                  context,
                  text: '成长',
                  dotColor: const Color(0xFF4FD1C5), // 青蓝色
                ),
              ],
            ),
            const SizedBox(height: 24),

            // === 示例 8: 基础构造函数（完全自定义） ===
            const Text(
              '8. 完全自定义的标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const DotLabel(
              dotColor: Colors.redAccent,
              text: 'URGENT',
              textColor: Colors.red,
              dotSize: 8.0,
              spacing: 8.0,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 24),

            // === 示例 9: 卡片中使用 ===
            const Text(
              '9. 在卡片中使用标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DotLabel.objective(context, text: 'Q1 目标'),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '完成产品原型设计',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DotLabel.keyResult(context, text: '设计 20 个界面'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建列表项的辅助方法
  Widget _buildListItem(
    BuildContext context, {
    required Widget label,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          label,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
