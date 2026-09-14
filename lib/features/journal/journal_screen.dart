import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/readings/reading_session.dart';
import '../../domain/spreads/spread_catalog.dart';

/// All saved readings, newest first, as returned by
/// [ReadingRepository.list].
final journalProvider = FutureProvider.autoDispose<List<ReadingSession>>(
  (ref) => ref.watch(readingRepositoryProvider).list(),
);

String formatJournalDate(DateTime d) {
  final local = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String journalSummary(ReadingSession session) {
  final revealed = session.placed.where((c) => c.revealed).length;
  if (session.placed.isEmpty) return 'Nenhuma carta ainda';
  return revealed == session.placed.length
      ? '${session.placed.length} carta(s) reveladas'
      : '${session.placed.length} carta(s), $revealed revelada(s)';
}

/// Local reading history (M8): lists every saved reading. Tapping an entry
/// opens a read-only summary in [JournalDetailScreen].
///
/// Scoping note: the persistence layer only tracks one "in progress"
/// session per reading mode (`active(mode)`), so there is no in-place
/// restore/edit semantics for an arbitrary past journal entry — only the
/// most recent session per mode can ever be "active". Re-entering an old
/// reading as an editable table would silently fabricate multi-session
/// behavior that doesn't exist yet, so v1 keeps the Journal purely a
/// read-only history with delete, not a way back into an editable board.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(journalProvider);

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Diário de leituras')),
      body: readings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Não foi possível carregar o diário.')),
        data: (sessions) => sessions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_edu_outlined,
                        size: 36,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text('Nenhuma leitura salva ainda.'),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                key: const Key('journal-list'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final mode = SpreadCatalog.byId(session.spreadId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        key: Key('journal-item-${session.readingId}'),
                        leading: CircleAvatar(
                          backgroundColor: scheme.primary.withValues(
                            alpha: .16,
                          ),
                          foregroundColor: scheme.primary,
                          child: const Icon(Icons.style_outlined, size: 20),
                        ),
                        title: Text(mode.name),
                        subtitle: Text(
                          '${formatJournalDate(session.createdAt)}'
                          '${session.question.isNotEmpty ? '\n"${session.question}"' : ''}'
                          '\n${journalSummary(session)}',
                        ),
                        isThreeLine: true,
                        onTap: () =>
                            context.push('/journal/${session.readingId}'),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
