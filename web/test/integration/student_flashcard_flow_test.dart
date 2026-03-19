// test/integration/student_flashcard_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_first_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Student Flashcard Flow', () {
    testWidgets("Flashcard ro'yxati → mashq → flip", (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byIcon(Icons.style_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Flashcardlar'), findsOneWidget);

      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mashq boshlash'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('flashcard_back')), findsOneWidget);
    });

    testWidgets('TTS tugmasi - xato chiqarmaydi', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byIcon(Icons.style_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mashq boshlash'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tts_button')));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
