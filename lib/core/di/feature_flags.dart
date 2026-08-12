import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature flags gate premium functionality at the use-case boundary.
///
/// This is the architectural seam for monetization: use cases check this
/// provider before issuing work, so gated features never even start for
/// free users. The router also reads it to redirect to the paywall before
/// a gated page builds.
class FeatureFlags {
  const FeatureFlags({
    this.isPremium = false,
    this.pdfImportEnabled = false,
    this.adaptiveSpeedEnabled = false,
    this.unlimitedAi = false,
    this.allTimeStats = false,
  });

  final bool isPremium;
  final bool pdfImportEnabled;
  final bool adaptiveSpeedEnabled;
  final bool unlimitedAi;
  final bool allTimeStats;

  /// Free-tier default.
  factory FeatureFlags.free() => const FeatureFlags();

  /// Premium unlocks everything in Phase 1.
  factory FeatureFlags.premium() => const FeatureFlags(
        isPremium: true,
        pdfImportEnabled: true,
        adaptiveSpeedEnabled: true,
        unlimitedAi: true,
        allTimeStats: true,
      );

  FeatureFlags copyWith({bool? isPremium}) {
    return FeatureFlags(
      isPremium: isPremium ?? this.isPremium,
      pdfImportEnabled: isPremium ?? this.isPremium,
      adaptiveSpeedEnabled: isPremium ?? this.isPremium,
      unlimitedAi: isPremium ?? this.isPremium,
      allTimeStats: isPremium ?? this.isPremium,
    );
  }
}

/// Mutable so settings/paywall can flip it; defaults to free.
final featureFlagsProvider = StateProvider<FeatureFlags>((ref) => FeatureFlags.free());
