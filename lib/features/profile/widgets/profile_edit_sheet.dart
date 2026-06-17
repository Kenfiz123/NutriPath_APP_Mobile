import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/widgets.dart';

class ProfileEditSheet extends StatefulWidget {
  const ProfileEditSheet({required this.member, super.key});

  final Member member;

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _calories;
  late final TextEditingController _water;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.member.name);
    _email = TextEditingController(text: widget.member.email);
    _calories = TextEditingController(text: '${widget.member.calorieTarget}');
    _water = TextEditingController(text: '${widget.member.waterTargetGlasses}');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _calories.dispose();
    _water.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionHeader(title: 'Chỉnh hồ sơ'),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Họ tên'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Mục tiêu calo/ngày'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _water,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Mục tiêu nước ly/ngày',
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'name': _name.text.trim(),
              'email': _email.text.trim(),
              'calorieTarget':
                  int.tryParse(_calories.text.trim()) ??
                  widget.member.calorieTarget,
              'waterTargetGlasses':
                  int.tryParse(_water.text.trim()) ??
                  widget.member.waterTargetGlasses,
            }),
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }
}
