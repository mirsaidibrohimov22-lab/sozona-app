// test/integration/offline_mode_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_first_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Mode Tests', () {
    testWidgets('Online holatda offline banner ko\'rinmaydi', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byKey(const Key('offline_banner')), findsNothing);
    });

    testWidgets('Keshda saqlangan flashcardlar ko\'rinadi', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byIcon(Icons.style_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
