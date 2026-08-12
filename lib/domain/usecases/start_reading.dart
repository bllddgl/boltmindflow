import '../entities/reading_session.dart';
import '../repositories/reading_repository.dart';
import '../result.dart';

/// Start a new reading session.
class StartReading {
  StartReading(this._repo);
  final ReadingRepository _repo;

  Future<Result<ReadingSession>> call(String documentId) {
    return _repo.startSession(documentId);
  }
}
