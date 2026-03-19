// test/integration/teacher_create_publish_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_first_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teacher Create & Publish Flow', () {
    testWidgets('AI quiz generatsiya → sinflarga publish', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('type_quiz')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('topic_field')),
        'Modalverben',
      );
      await tester.tap(find.text('Generatsiya qilish'));
      await tester.pumpAndSettle(const Duration(seconds: 15));

      expect(find.text("Ko'rib chiqish"), findsOneWidget);
      await tester.tap(find.text("E'lon qilish"));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text("Muvaffaqiyatli e'lon qilindi"), findsOneWidget);
    });

    testWidgets('Yangi sinf yaratish', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byIcon(Icons.group_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('class_name_field')),
        '10-A sinf',
      );
      await tester.tap(find.text('Yaratish'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('10-A sinf'), findsOneWidget);
    });
  });
}
