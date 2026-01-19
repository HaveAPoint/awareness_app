/home/crh/awareness_app/frontend/lib/ui/screens/journal/widgets/pending_thought_card.dart
  文件左滑会出现三个小按键 我希望在不影响这个交互逻辑的前提之下 加一个单击展开的效果 这两个
  交互逻辑是初始状态的两个分支 不可以共存 请先plan

目标栏需要增加描述 描述增加在任务名的下面

# Flutter任务：修改关键结果编辑表单

**背景：**
我正在开发一个 OKR 管理应用。目前有一个“编辑目标”页面，其界面如附件 `image_0.png` 所示。
在这个页面中，用户可以添加和编辑“关键结果”（Key Results）。当前的 UI 包含“关键结果标题”、“目标值”和“单位”三个输入框。

**目标：**
修改关键结果的输入区域，将其简化为基于时间的设置，以配合番茄钟功能。

**具体要求：**
1.  **移除字段：** 在关键结果编辑模块中，删除“目标值”和“单位”这两个输入框。
2.  **修改字段：** 将现有的“关键结果 1”输入框标签明确为“关键结果标题”。
3.  **新增字段：** 在标题输入框下方，新增一个数字输入框 (`TextField` 或 `TextFormField`)。
    * 标签 (Label/Decoration) 设置为：“预期时间 (小时)”。
    * 输入类型 (`keyboardType`) 限制为数字，允许输入整数或小数（例如 `TextInputType.numberWithOptions(decimal: true)`）。
    * 添加一个后缀文本 “小时” 以明确单位。
4.  **数据模型更新：** 请同步更新用于存储关键结果的数据模型类。移除原来的 `targetValue` 和 `unit` 字段，替换为一个新的 `double` 类型的字段，例如 `estimatedHours`，用于存储用户输入的预期时间。
5.  **参考图像：** 请依据 `image_0.png` 的现有 Material Design 风格进行修改，保持 UI 一致性。

请提供修改后的 Widget 代码片段以及更新后的数据模型类定义。