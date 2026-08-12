import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/di/data_providers.dart';
import '../../domain/entities/review_card.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/result.dart';

/// Review view state.
sealed class ReviewState {
  const ReviewState();
}

class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

class ReviewLoaded extends ReviewState {
  const ReviewLoaded(this.cards, this.currentIndex);
  final List<ReviewCard> cards;
  final int currentIndex;

  ReviewCard? get currentCard =>
      currentIndex < cards.length ? cards[currentIndex] : null;
  int get remaining => cards.length - currentIndex;
  bool get isFinished => currentIndex >= cards.length;
}

class ReviewError extends ReviewState {
  const ReviewError(this.message);
  final String message;
}

/// Notifier managing the review session.
class ReviewNotifier extends StateNotifier<ReviewState> {
  ReviewNotifier(this._ref) : super(const ReviewInitial());

  final Ref _ref;

  Future<void> load() async {
    state = const ReviewLoading();
    final getDueCards = _ref.read(getDueCardsProvider);
    final result = await getDueCards();
    result.when(
      success: (cards) {
        if (cards.isEmpty) {
          state = const ReviewLoaded([], 0);
        } else {
          state = ReviewLoaded(cards, 0);
        }
      },
      failure: (f) => state = ReviewError(f.message),
    );
  }

  Future<void> grade(ReviewGrade grade) async {
    final current = state;
    if (current is! ReviewLoaded || current.currentCard == null) return;

    final card = current.currentCard!;
    final gradeCard = _ref.read(gradeCardProvider);
    await gradeCard(card.id, grade);

    final nextIndex = current.currentIndex + 1;
    state = ReviewLoaded(current.cards, nextIndex);
  }

  void reset() {
    state = const ReviewInitial();
    load();
  }
}

final reviewNotifierProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  final notifier = ReviewNotifier(ref);
  notifier.load();
  return notifier;
});
