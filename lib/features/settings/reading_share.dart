import '../../domain/decks/tarot_deck.dart';
import '../../domain/readings/reading_session.dart';
import '../../domain/spreads/spread_catalog.dart';
import '../../infrastructure/persistence/reading_codec.dart';

/// Export/sharing helpers for a single reading (M9, contract section 13).
///
/// Kept independent of any specific screen so both the Journal detail view
/// and any future entry point can reuse it without duplicating read logic.

String _formatDate(DateTime d) {
  final local = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Builds a plain-text share summary: spread name, date, the drawn cards
/// (canonical name when revealed, "Carta fechada" otherwise) and,
/// only when [includePrivateNotes] is explicitly true, the question/notes.
///
/// Question and notes must never be included by default — sharing private
/// text is only ever an explicit user action (contract section 13/15).
String buildReadingShareText(
  ReadingSession session,
  TarotDeck deck, {
  bool includePrivateNotes = false,
}) {
  final mode = SpreadCatalog.byId(session.spreadId);
  final placed = [...session.placed]
    ..sort((a, b) => a.drawIndex.compareTo(b.drawIndex));
  final buffer = StringBuffer()
    ..writeln('Arcanum — ${mode.name}')
    ..writeln(_formatDate(session.createdAt));
  if (includePrivateNotes && session.question.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('Pergunta: ${session.question}');
  }
  buffer
    ..writeln()
    ..writeln('Cartas:');
  if (placed.isEmpty) {
    buffer.writeln('- Nenhuma carta foi colocada.');
  }
  for (final card in placed) {
    final name = card.revealed
        ? deck.card(card.cardId).canonicalName
        : 'Carta fechada';
    buffer.writeln('- ${session.cardLabel(card)}: $name');
  }
  if (includePrivateNotes && session.notes.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('Notas: ${session.notes}');
  }
  buffer
    ..writeln()
    ..write('Leitura local — não enviada a nenhum servidor.');
  return buffer.toString();
}

/// Full JSON backup of the reading session, reusing the canonical codec so
/// the export format matches persistence exactly (no separate ad-hoc
/// serialization to keep in sync).
String buildReadingJsonExport(
  ReadingSession session, {
  bool includePrivateNotes = false,
}) => ReadingCodec.encode(
  includePrivateNotes
      ? session
      : session.annotate(question: '', notes: '', now: session.updatedAt),
);
