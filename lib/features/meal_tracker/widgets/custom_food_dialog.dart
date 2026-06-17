import 'package:flutter/material.dart';

class CustomFoodDialog extends StatefulWidget {
  const CustomFoodDialog({super.key});
  @override
  State<CustomFoodDialog> createState() => _CustomFoodDialogState();
}

class _CustomFoodDialogState extends State<CustomFoodDialog> {
  final _name = TextEditingController();
  final _desc = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ước tính món tự nấu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Tên món'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Nguyên liệu & cách nấu',
              hintText: 'Ví dụ: 100g ức gà áp chảo, 1 chén cơm gạo lứt...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'name': _name.text,
            'rawText': _desc.text,
            'servings': 1,
          }),
          child: const Text('Gửi AI'),
        ),
      ],
    );
  }
}
