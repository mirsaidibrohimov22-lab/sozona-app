// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Audio Player Widget Test
// QO'YISH: test/widget/student/listening/audio_player_widget_test.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/features/student/listening/presentation/widgets/audio_player_widget.dart';

void main() {
  group('AudioPlayerWidget', () {
    late bool isPlaying;
    late Duration currentPosition;
    late Duration totalDuration;
    late bool playPauseCalled;
    late Duration? seekPosition;

    setUp(() {
      isPlaying = false;
      currentPosition = const Duration(seconds: 30);
      totalDuration = const Duration(minutes: 3);
      playPauseCalled = false;
      seekPosition = null;
    });

    Widget createWidget() {
      return MaterialApp(
        home: Scaffold(
          body: AudioPlayerWidget(
            audioUrl: 'https://example.com/audio.mp3',
            isPlaying: isPlaying,
            currentPosition: currentPosition,
            totalDuration: totalDuration,
            onPlayPause: () {
              playPauseCalled = true;
            },
            onSeek: (position) {
              seekPosition = position;
            },
          ),
        ),
      );
    }

    testWidgets('should display audio player controls', (tester) async {
      // arrange
      await tester.pumpWidget(createWidget());

      // assert
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.replay_10), findsOneWidget);
      expect(find.byIcon(Icons.forward_10), findsOneWidget);
    });

    testWidgets('should display play icon when not playing', (tester) async {
      // arrange
      isPlaying = false;
      await tester.pumpWidget(createWidget());

      // assert
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('should display pause icon when playing', (tester) async {
      // arrange
      isPlaying = true;
      await tester.pumpWidget(createWidget());

      // assert
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('should display correct time format', (tester) async {
      // arrange
      await tester.pumpWidget(createWidget());

      // assert
      expect(find.text('00:30'), findsOneWidget); // current position
      expect(find.text('03:00'), findsOneWidget); // total duration
    });

    testWidgets('should call onPlayPause when play button is tapped',
        (tester) async {
      // arrange
      await tester.pumpWidget(createWidget());

      // act
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // assert
      expect(playPauseCalled, true);
    });

    testWidgets('should show speed control menu', (tester) async {
      // arrange
      await tester.pumpWidget(createWidget());

      // assert
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.byType(PopupMenuButton<double>), findsOneWidget);
    });

    testWidgets('should show all speed options when menu is opened',
        (tester) async {
      // arrange
      await tester.pumpWidget(createWidget());

      // act
      await tester.tap(find.byType(PopupMenuButton<double>));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('0.5x'), findsOneWidget);
      expect(find.text('0.75x'), findsOneWidget);
      expect(find.text('1.0x'), findsWidgets);
      expect(find.text('1.25x'), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);
      expect(find.text('2.0x'), findsOneWidget);
    });

    testWidgets('should update slider position', (tester) async {
      // arrange
      await tester.pumpWidget(createWidget());
      final slider = find.byType(Slider);

      // act
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // assert
      expect(seekPosition, isNotNull);
    });

    testWidgets('should have rewind and forward buttons', (tester) async {
      // arrange
      await tester.pumpWidget(createWidget());

      // assert
      expect(find.byIcon(Icons.replay_10), findsOneWidget);
      expect(find.byIcon(Icons.forward_10), findsOneWidget);
    });

    testWidgets('should display total duration correctly', (tester) async {
      // arrange
      totalDuration = const Duration(minutes: 5, seconds: 30);
      await tester.pumpWidget(createWidget());

      // assert
      expect(find.text('05:30'), findsOneWidget);
    });

    testWidgets('should display zero padding for single digit seconds',
        (tester) async {
      // arrange
      currentPosition = const Duration(seconds: 5);
      await tester.pumpWidget(createWidget());

      // assert
      expect(find.text('00:05'), findsOneWidget);
    });
  });
}
