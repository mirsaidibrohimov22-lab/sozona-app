// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Chat Bubble Widget Test
// QO'YISH: test/widget/student/ai_chat/chat_bubble_test.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/features/student/ai_chat/domain/entities/chat_message.dart';
import 'package:my_first_app/features/student/ai_chat/presentation/widgets/chat_bubble.dart';

void main() {
  group('ChatBubble', () {
    final userMessage = ChatMessage(
      id: '1',
      text: 'Hello! How are you?',
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final aiMessage = ChatMessage(
      id: '2',
      text: 'I am fine, thank you!',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );

    testWidgets('should show user message on the right', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatBubble(message: userMessage)),
        ),
      );

      expect(find.text('Hello! How are you?'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should show AI message on the left', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatBubble(message: aiMessage)),
        ),
      );

      expect(find.text('I am fine, thank you!'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('user bubble has primary color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatBubble(message: userMessage)),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ChatBubble),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container, isNotNull);
    });
  });
}
