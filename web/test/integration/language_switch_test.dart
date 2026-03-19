// test/integration/language_switch_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_first_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Language Switch Tests', () {
    testWidgets("UI tilni inglizchaga o'zgartirish", (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ui_language_toggle')));
      await tester.pumpAndSettle();

      expect(find.text("Today's Plan"), findsOneWidget);
    });

    testWidgets("O'rganish tilini o'zgartirish", (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('learning_language_en')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.byKey(const Key('learning_language_en_selected')),
        findsOneWidget,
      );
    });
  });
}
