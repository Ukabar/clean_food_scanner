import 'package:clean_food_scanner/app/app.dart';
import 'package:clean_food_scanner/data/local/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await LocalStorage.instance.initialize();
    await LocalStorage.instance.setOnboardingComplete(true);
  });

  testWidgets('Labelora app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LabeloraApp()));

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
