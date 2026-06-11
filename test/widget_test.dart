import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fe/src/app.dart';

void main() {
  testWidgets('NutriPath app boots to auth guard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: NutriPathApp()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.eco), findsOneWidget);
    expect(find.text('NutriPath'), findsOneWidget);
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
  });
}
