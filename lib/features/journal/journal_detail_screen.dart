import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../domain/readings/reading_session.dart';
import '../../domain/spreads/spread_catalog.dart';
import '../settings/reading_share.dart';
import 'journal_screen.dart';
import '../free_reading/reading_controller.dart';
import '../home/home_screen.dart';

/// One saved reading, looked up by id, for the read-only detail view.
final journalEntryProvider = FutureProvider.autoDispose
    .family<ReadingSession?, String>(
      (ref, readingId) => ref.watch(readingRepositoryProvider).read(readingId),
    );

/// Read-only summary of a single past reading, with a Delete action.
///
/// This is intentionally NOT a re-editable board: see the scoping note in
/// [JournalScreen]. Only the mode/date/question/notes and the drawn cards
/// (canonical name when revealed, "Carta fechada" otherwise, plus the
/// spread slot label when the reading belongs to a predefined spread) are
/// shown.
class JournalDetailScreen extends ConsumerWidget {
  const JournalDetailScreen({super.key, required this.readingId});
  final String readingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(journalEntryProvider(readingId));
    final deck = ref.watch(deckProvider);

    Future<void> delete(ReadingSession session) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir leitura?'),
          content: const Text('Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await ref.read(readingRepositoryProvider).delete(session.readingId);
      ref.invalidate(journalProvider);
      ref.invalidate(recentReadingsProvider);
      ref.invalidate(readingControllerProviderFor(session.spreadId));
      if (!context.mounted) return;
      context.pop();
    }

    Future<void> shareSummary(ReadingSession session) async {
      final includePrivate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Compartilhar leitura'),
          content: const Text(
            'Incluir a pergunta e as notas privadas no texto compartilhado?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Só as cartas'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Incluir pergunta e notas'),
            ),
          ],
        ),
      );
      if (includePrivate == null) return;
      final text = buildReadingShareText(
        session,
        deck,
        includePrivateNotes: includePrivate,
      );
      try {
        await SharePlus.instance.share(ShareParams(text: text));
      } on Object {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Compartilhamento indisponível. Use Exportar JSON.',
              ),
            ),
          );
        }
      }
    }

    Future<void> exportJson(ReadingSession session) async {
      final include = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exportar leitura'),
          content: const Text(
            'O JSON contém a ordem do baralho e cartas ainda fechadas. Deseja incluir também sua pergunta e notas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Sem pergunta e notas'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Incluir pergunta e notas'),
            ),
          ],
        ),
      );
      if (include == null) return;
      final json = buildReadingJsonExport(
        session,
        includePrivateNotes: include,
      );
      await Clipboard.setData(ClipboardData(text: json));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'JSON da leitura copiado para a área de transferência.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Leitura salva')),
      body: entry.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Não foi possível carregar a leitura.')),
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Leitura não encontrada.'));
          }
          final mode = SpreadCatalog.byId(session.spreadId);
          final placed = [...session.placed]
            ..sort((a, b) => a.drawIndex.compareTo(b.drawIndex));
          return ListView(
            key: const Key('journal-detail'),
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await context.push('/journal/$readingId/table');
                  if (context.mounted) {
                    ref.invalidate(journalEntryProvider(readingId));
                  }
                },
                icon: const Icon(Icons.view_quilt_outlined),
                label: const Text('Abrir tiragem na mesa'),
              ),
              const SizedBox(height: 12),
              Text(mode.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(formatJournalDate(session.createdAt)),
              if (session.question.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Pergunta', style: Theme.of(context).textTheme.labelLarge),
                Text(session.question),
              ],
              if (session.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Notas', style: Theme.of(context).textTheme.labelLarge),
                Text(session.notes),
              ],
              const SizedBox(height: 24),
              Text('Cartas', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              if (placed.isEmpty) const Text('Nenhuma carta foi colocada.'),
              for (final card in placed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${_slotLabel(session, card)}${card.revealed ? deck.card(card.cardId).canonicalName : 'Carta fechada'}',
                  ),
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('journal-share-button'),
                    onPressed: () => shareSummary(session),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartilhar'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('journal-export-json-button'),
                    onPressed: () => exportJson(session),
                    icon: const Icon(Icons.data_object_outlined),
                    label: const Text('Exportar JSON'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('journal-delete-button'),
                onPressed: () => delete(session),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _slotLabel(ReadingSession session, PlacedCard card) {
    return '${session.cardLabel(card)}: ';
  }
}
