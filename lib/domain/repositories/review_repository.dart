import '../entities/review_card.dart';
import '../result.dart';

/// Abstract interface for spaced-repetition review cards.
abstract class ReviewRepository {
  Future<Result<List<ReviewCard>>> getDueCards({DateTime? asOf});
  Future<Result<List<ReviewCard>>> getCardsForDocument(String documentId);
  Future<Result<ReviewCard>> createCard({required String documentId, required ReviewCardType type, required String front, required String back});
  Future<Result<ReviewCard>> gradeCard(String cardId, {required ReviewGrade grade});
  Future<Result<void>> deleteCard(String cardId);
}

/// The four standard SRS grades (Anki-style).
enum ReviewGrade { again, hard, good, easy }
