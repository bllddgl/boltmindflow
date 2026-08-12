import '../entities/review_card.dart';
import '../repositories/review_repository.dart';
import '../result.dart';

/// Fetch review cards due for practice today.
class GetDueCards {
  GetDueCards(this._repo);
  final ReviewRepository _repo;

  Future<Result<List<ReviewCard>>> call({DateTime? asOf}) {
    return _repo.getDueCards(asOf: asOf);
  }
}
