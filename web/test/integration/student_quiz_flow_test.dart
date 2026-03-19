// test/integration/student_quiz_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_first_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Student Quiz Flow', () {
    testWidgets("Quiz ro'yxati → o'ynash → natija", (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byIcon(Icons.quiz_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Quizlar'), findsOneWidget);

      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Boshlash'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('option_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keyingisi'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('%'), findsOneWidget);
    });

    testWidgets('AI Quiz yaratish', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byIcon(Icons.quiz_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.text('AI Quiz'), findsOneWidget);
    });
  });
}
