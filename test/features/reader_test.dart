import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/features/reader/reader_providers.dart';

void main() {
  group('DisplayState', () {
    test('default state is empty/idle', () {
      const state = DisplayState();
      expect(state.text, '');
      expect(state.blockIndex, 0);
      expect(state.isPlaying, isFalse);
      expect(state.isPaused, isFalse);
      expect(state.isFinished, isFalse);
      expect(state.progress, 0.0);
      expect(state.wordsRead, 0);
      expect(state.totalWords, 0);
      expect(state.stats, isNull);
    });

    test('copyWith updates only specified fields', () {
      const original = DisplayState();
      final updated = original.copyWith(
        text: 'hello',
        isPlaying: true,
        progress: 0.5,
      );
      expect(updated.text, 'hello');
      expect(updated.isPlaying, isTrue);
      expect(updated.isPaused, isFalse);
      expect(updated.progress, 0.5);
      expect(updated.blockIndex, 0);
    });

    test('copyWith preserves stats when not specified', () {
      const state = DisplayState(text: 'test');
      final updated = state.copyWith(text: 'new');
      expect(updated.text, 'new');
      expect(updated.stats, isNull);
    });
  });
}
