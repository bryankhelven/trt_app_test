import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../free_reading/free_reading_screen.dart';
import '../free_reading/reading_controller.dart';
import 'journal_detail_screen.dart';

/// Opening saved state is an explicit journal action, never automatic resume.
class SavedTableScreen extends ConsumerWidget {
  const SavedTableScreen({super.key, required this.readingId});
  final String readingId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(journalEntryProvider(readingId))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Não foi possível abrir esta tiragem.'),
            ),
          ),
          data: (session) => session == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: const Center(child: Text('Tiragem não encontrada.')),
                )
              : ProviderScope(
                  overrides: [
                    readingControllerProviderFor(session.spreadId).overrideWith(
                      () => ReadingController(
                        session.spread,
                        initialSession: session,
                      ),
                    ),
                  ],
                  child: FreeReadingScreen(modeId: session.spreadId),
                ),
        );
  }
}
