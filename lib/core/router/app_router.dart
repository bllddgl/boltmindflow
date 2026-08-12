import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/app_providers.dart';
import '../di/feature_flags.dart';
import '../responsive/layout_type.dart';
import '../theme/app_theme.dart';
import '../../features/ai/ai_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/reader/reader_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/stats/stats_screen.dart';

/// Adaptive root scaffold: [NavigationBar] on phone, [NavigationRail] on
/// tablet/desktop. Same route tree; only the chrome changes.
class _AdaptiveShell extends ConsumerWidget {
  const _AdaptiveShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final layout = LayoutBreakpoints.classify(width);
    final theme = Theme.of(context);

    final destinations = const [
      (icon: Icons.library_books_outlined, label: 'Library'),
      (icon: Icons.replay_outlined, label: 'Review'),
      (icon: Icons.bar_chart_outlined, label: 'Stats'),
      (icon: Icons.settings_outlined, label: 'Settings'),
    ];

    if (layout == LayoutType.phone) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: navigationShell.goBranch,
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    final extended = layout == LayoutType.desktop;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: navigationShell.goBranch,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('MindFlow', style: theme.textTheme.titleLarge),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

/// Central GoRouter configuration.
///
/// The shell hosts the four tabs; the reader is a full-screen route pushed
/// on top so reading is immersive. [redirect] enforces onboarding and
/// premium gating before a page builds.
GoRouter buildRouter(Ref ref) {
  final hasOnboarded = ref.read(hasOnboardedProvider);
  final flags = ref.read(featureFlagsProvider);

  final premiumRoutes = <String>{'/reader/:id/ai'};

  return GoRouter(
    initialLocation: '/library',
    redirect: (context, state) {
      final path = state.matchedLocation;
      if (!hasOnboarded && path != '/onboarding') return '/onboarding';
      if (premiumRoutes.contains(path) && !flags.isPremium) {
        return '/paywall?return=${Uri.encodeComponent(path)}';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, __) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/import',
        redirect: (_, state) => '/library',
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => _AdaptiveShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/review', builder: (_, __) => const ReviewScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/reader/:id',
        builder: (_, state) => ReaderScreen(documentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reader/:id/ai',
        builder: (_, state) => AiScreen(documentId: state.pathParameters['id']!),
      ),
    ],
  );
}

/// Router provider so widgets can access it via `ref.watch(routerProvider)`.
final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));

