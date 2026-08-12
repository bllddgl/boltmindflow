import '../entities/review_card.dart';
import '../repositories/review_repository.dart';
import '../result.dart';

/// Grade a review card; the repository applies the SM-2 algorithm and
/// schedules the next due date.
class GradeCard {
  GradeCard(this._repo);
  final ReviewRepository _repo;

  Future<Result<ReviewCard>> call(String cardId, ReviewGrade grade) {
    return _repo.gradeCard(cardId, grade: grade);
  }
}
