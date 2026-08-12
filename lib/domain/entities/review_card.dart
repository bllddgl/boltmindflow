/// A spaced-repetition card generated from AI extraction.
///
/// Uses the SM-2 algorithm state fields ([ease], [intervalDays], [repetitions]).
/// Swapping to FSRS later needs no schema change — these columns suffice.
class ReviewCard {
  const ReviewCard({
    required this.id,
    required this.documentId,
    required this.cardType,
    required this.front,
    required this.back,
    required this.ease,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
    required this.createdAt,
  });

  final String id;
  final String documentId;
  final ReviewCardType cardType;
  final String front;
  final String back;
  final double ease; // SM-2 ease factor (starts 2.5)
  final int intervalDays;
  final int repetitions;
  final DateTime dueAt;
  final DateTime createdAt;

  bool get isDue => DateTime.now().isAfter(dueAt);
}

enum ReviewCardType { flashcard, vocab, quiz }
