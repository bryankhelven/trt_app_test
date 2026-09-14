import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/free_reading/free_reading_screen.dart';
import '../../features/journal/journal_detail_screen.dart';
import '../../features/journal/saved_table_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/library/card_detail_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/spreads/spread_reading_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/reading/free',
        builder: (context, state) => const FreeReadingScreen(),
      ),
      GoRoute(
        path: '/reading/spread/:id',
        builder: (context, state) =>
            SpreadReadingScreen(modeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/library/:cardId',
        builder: (context, state) => CardDetailScreen(
          cardId: state.pathParameters['cardId']!,
          navigation: state.extra as LibraryNavigationContext?,
        ),
      ),
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '/journal/:readingId/table',
        builder: (context, state) =>
            SavedTableScreen(readingId: state.pathParameters['readingId']!),
      ),
      GoRoute(
        path: '/journal/:readingId',
        builder: (context, state) =>
            JournalDetailScreen(readingId: state.pathParameters['readingId']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
