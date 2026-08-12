import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/feature_flags.dart';
import '../../data/di/data_providers.dart';
import '../../domain/entities/stats_snapshot.dart';
import '../../domain/result.dart';

/// Stats view state.
sealed class StatsState {
  const StatsState();
}

class StatsLoading extends StatsState {
  const StatsLoading();
}

class StatsLoaded extends StatsState {
  const StatsLoaded(this.snapshot, {required this.isPremium});
  final StatsSnapshot snapshot;
  final bool isPremium;
}

class StatsError extends StatsState {
  const StatsError(this.message);
  final String message;
}

/// Notifier managing the stats view.
class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier(this._ref) : super(const StatsLoading());

  final Ref _ref;

  Future<void> load() async {
    final flags = _ref.read(featureFlagsProvider);
    final now = DateTime.now();
    final from = flags.allTimeStats
        ? DateTime(now.year - 1, now.month, now.day)
        : now.subtract(const Duration(days: 7));

    final getStats = _ref.read(getStatsProvider);
    final result = await getStats(from: from, to: now);

    result.when(
      success: (snapshot) =>
          state = StatsLoaded(snapshot, isPremium: flags.isPremium),
      failure: (f) => state = StatsError(f.message),
    );
  }
}

final statsNotifierProvider =
    StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  final notifier = StatsNotifier(ref);
  notifier.load();
  return notifier;
});
