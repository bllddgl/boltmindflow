import '../entities/stats_snapshot.dart';
import '../repositories/stats_repository.dart';
import '../result.dart';

/// Fetch a stats snapshot for a time window.
///
/// Free tier: 7-day window. Premium: all-time. The window is decided by the
/// caller (presentation), which reads feature flags.
class GetStats {
  GetStats(this._repo);
  final StatsRepository _repo;

  Future<Result<StatsSnapshot>> call({required DateTime from, required DateTime to}) {
    return _repo.getSnapshot(from: from, to: to);
  }
}
