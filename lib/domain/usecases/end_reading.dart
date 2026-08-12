import '../entities/reading_session.dart';
import '../repositories/reading_repository.dart';
import '../result.dart';

/// End a reading session with aggregated stats.
class EndReading {
  EndReading(this._repo);
  final ReadingRepository _repo;

  Future<Result<ReadingSession>> call({
    required String sessionId,
    required int wordsRead,
    required int blocksRead,
    required int avgWpm,
    required double focusScore,
  }) {
    return _repo.endSession(
      sessionId,
      wordsRead: wordsRead,
      blocksRead: blocksRead,
      avgWpm: avgWpm,
      focusScore: focusScore,
    );
  }
}
