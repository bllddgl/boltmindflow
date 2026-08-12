import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/features/stats/stats_providers.dart';

void main() {
  group('StatsState', () {
    test('loading state', () {
      expect(const StatsLoading(), isA<StatsState>());
    });

    test('loaded state carries snapshot and premium flag', () {
      const state = StatsLoaded(null, isPremium: true);
      expect(state.isPremium, isTrue);
    });

    test('error state carries message', () {
      const state = StatsError('fail');
      expect(state.message, 'fail');
    });
  });
}
