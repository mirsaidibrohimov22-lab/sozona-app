// test/integration/student_micro_session_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_first_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Micro Session Flow', () {
    testWidgets('Mikro-sessiya boshlash → tugatish', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Mikro-sessiya'), findsOneWidget);
      await tester.tap(find.text('Boshlash'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byKey(const Key('session_timer')), findsOneWidget);

      await tester.tap(find.byKey(const Key('activity_card')).first);
      await tester.pumpAndSettle();
    });

    testWidgets("Sessiyani yarim yo'lda to'xtatish", (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Boshlash'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Chiqishni xohlaysizmi?'), findsOneWidget);
      await tester.tap(find.text('Ha'));
      await tester.pumpAndSettle();

      expect(find.text('Bugungi reja'), findsOneWidget);
    });
  });
}
