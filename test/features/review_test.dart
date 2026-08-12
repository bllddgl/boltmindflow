import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/features/review/review_providers.dart';

void main() {
  group('ReviewState', () {
    test('initial state is ReviewInitial', () {
      expect(const ReviewInitial(), isA<ReviewState>());
    });

    test('loaded state with empty cards is finished', () {
      const state = ReviewLoaded([], 0);
      expect(state.isFinished, isTrue);
      expect(state.remaining, 0);
      expect(state.currentCard, isNull);
    });

    test('loaded state tracks current card and remaining', () {
      final cards = List.generate(3, (i) => _FakeCard(id: 'card-$i'));
      final state = ReviewLoaded(cards, 1);
      expect(state.isFinished, isFalse);
      expect(state.remaining, 2);
      expect(state.currentCard, isNotNull);
    });

    test('loaded state at end is finished', () {
      final cards = List.generate(2, (i) => _FakeCard(id: 'card-$i'));
      final state = ReviewLoaded(cards, 2);
      expect(state.isFinished, isTrue);
      expect(state.remaining, 0);
      expect(state.currentCard, isNull);
    });
  });
}

class _FakeCard {
  const _FakeCard({required this.id});
  final String id;
}
