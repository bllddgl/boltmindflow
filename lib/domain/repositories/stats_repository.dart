import '../entities/stats_snapshot.dart';
import '../result.dart';

/// Abstract interface for reading statistics.
abstract class StatsRepository {
  /// Aggregated stats for a time window. Free tier requests 7 days; premium
  /// requests all-time.
  Future<Result<StatsSnapshot>> getSnapshot({required DateTime from, required DateTime to});

  /// Current streak (consecutive days with ≥1 reading session).
  Future<Result<int>> getCurrentStreak();

  /// Log a raw event (session, bookmark, review) for later aggregation.
  Future<Result<void>> logEvent({required String type, String? documentId, required Map<String, dynamic> payload});
}
