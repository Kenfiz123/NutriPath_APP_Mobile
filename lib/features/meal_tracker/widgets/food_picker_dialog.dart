import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/models.dart';

class FoodPickerDialog extends StatefulWidget {
  const FoodPickerDialog({required this.api, super.key});
  final ApiClient api;

  @override
  State<FoodPickerDialog> createState() => _FoodPickerDialogState();
}

class _FoodPickerDialogState extends State<FoodPickerDialog> {
  final _search = TextEditingController();
  late Future<List<Food>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getFoods();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _run() {
    setState(() {
      _future = widget.api.getFoods(_search.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn từ thư viện'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
                suffixIcon: IconButton(
                  onPressed: _run,
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => _run(),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: FutureBuilder<List<Food>>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final foods = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: foods.length,
                    itemBuilder: (context, i) {
                      final f = foods[i];
                      return ListTile(
                        title: Text(
                          f.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(f.category),
                        trailing: Text('${f.calories.round()} kcal'),
                        onTap: () => Navigator.pop(context, f),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
