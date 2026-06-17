import 'package:flutter/material.dart';

import '../../../core/models.dart';

class QuestionAnswerDialog extends StatefulWidget {
  const QuestionAnswerDialog({required this.questions, super.key});

  final List<JsonMap> questions;

  @override
  State<QuestionAnswerDialog> createState() => _QuestionAnswerDialogState();
}

class _QuestionAnswerDialogState extends State<QuestionAnswerDialog> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = [for (final _ in widget.questions) TextEditingController()];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bổ sung thông tin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.questions.length; i++) ...[
              TextField(
                controller: _controllers[i],
                decoration: InputDecoration(
                  labelText: asString(
                    widget.questions[i]['label'],
                    'Câu hỏi ${i + 1}',
                  ),
                  hintText: asString(widget.questions[i]['placeholder']),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final answers = <String, dynamic>{};
            for (var i = 0; i < widget.questions.length; i++) {
              final key = asString(widget.questions[i]['id'], 'q$i');
              answers[key] = _controllers[i].text.trim();
            }
            Navigator.pop(context, answers);
          },
          child: const Text('Tạo công thức'),
        ),
      ],
    );
  }
}
