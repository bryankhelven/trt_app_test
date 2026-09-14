import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/app/app.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/application/ports/reading_repository.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';
import 'package:tarot_app/domain/spreads/spread_catalog.dart';

import '../support/fixtures.dart';

/// In-memory [ReadingRepository] supporting multiple stored readings across
/// different `spreadId`s, as needed to exercise the Journal list/detail.
class MemoryReadings implements ReadingRepository {
  final Map<String, ReadingSession> byId = {};
  final Map<String, String> activeByMode = {};
  @override
  Future<void> save(ReadingSession session) async {
    byId[session.readingId] = session;
    activeByMode[session.spreadId] = session.readingId;
  }

  @override
  Future<ReadingSession?> active({String mode = 'FREE'}) async =>
      byId[activeByMode[mode]];
  @override
  Future<ReadingSession?> read(String id) async => byId[id];
  @override
  Future<List<ReadingSession>> list() async =>
      byId.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  @override
  Future<void> delete(String id) async {
    byId.remove(id);
    activeByMode.removeWhere((_, v) => v == id);
  }
}

Future<void> pumpJournal(WidgetTester tester, MemoryReadings repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        readingRepositoryProvider.overrideWithValue(repo),
        deckProvider.overrideWithValue(fixtureDeck()),
      ],
      child: const TarotApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Diário de leituras'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Diário de leituras'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Empty state shown when there are no saved readings', (
    tester,
  ) async {
    await pumpJournal(tester, MemoryReadings());
    expect(find.text('Nenhuma leitura salva ainda.'), findsOneWidget);
    expect(find.byKey(const Key('journal-list')), findsNothing);
  });

  testWidgets('List shows multiple saved readings across different modes with '
      'correct names and dates', (tester) async {
    final repo = MemoryReadings();
    final freeReading = fixtureSession()
        .placeNext(TablePosition(.2, .3), epoch)
        .reveal('card-0', epoch)
        .annotate(question: 'Como está meu ano?', notes: '', now: epoch);
    final spreadReading = ReadingSession.start(
      readingId: 'reading-2',
      deck: fixtureDeck(),
      drawOrder: fixtureDeck().cardIds,
      now: epoch.add(const Duration(days: 1)),
      spread: SpreadCatalog.cartaUnica,
    );
    await repo.save(freeReading);
    await repo.save(spreadReading);

    await pumpJournal(tester, repo);

    expect(find.byKey(const Key('journal-list')), findsOneWidget);
    expect(
      find.byKey(Key('journal-item-${freeReading.readingId}')),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('journal-item-${spreadReading.readingId}')),
      findsOneWidget,
    );
    expect(find.textContaining('Como está meu ano?'), findsOneWidget);
    expect(find.text('Tiragem Livre'), findsOneWidget);
    expect(find.text('Carta Única'), findsOneWidget);
  });

  testWidgets('Tapping a journal item opens the correct read-only detail with '
      'question, notes and card content', (tester) async {
    final repo = MemoryReadings();
    final reading = fixtureSession()
        .placeNext(TablePosition(.2, .3), epoch)
        .reveal('card-0', epoch)
        .annotate(
          question: 'Como está meu ano?',
          notes: 'Anotação pessoal',
          now: epoch,
        );
    await repo.save(reading);

    await pumpJournal(tester, repo);
    await tester.tap(find.byKey(Key('journal-item-${reading.readingId}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal-detail')), findsOneWidget);
    expect(find.text('Como está meu ano?'), findsOneWidget);
    expect(find.text('Anotação pessoal'), findsOneWidget);
    expect(find.textContaining('Fixture 0'), findsOneWidget);

    // No re-editable board reachable from the detail screen: it is a
    // read-only summary, not the Free Reading table.
    expect(find.byKey(const Key('table')), findsNothing);
    expect(find.byKey(const Key('deck')), findsNothing);
  });

  testWidgets(
    'Detail distinguishes revealed cards (canonical name) from unrevealed '
    '("Carta fechada") and shows slot labels for predefined spreads',
    (tester) async {
      final repo = MemoryReadings();
      var reading = ReadingSession.start(
        readingId: 'reading-3',
        deck: fixtureDeck(),
        drawOrder: fixtureDeck().cardIds,
        now: epoch,
        spread: SpreadCatalog.cartaUnica,
      );
      reading = reading.placeNext(
        SpreadCatalog.cartaUnica.slots.single.position,
        epoch,
        slotId: 'c1',
      );
      await repo.save(reading);

      await pumpJournal(tester, repo);
      await tester.tap(find.byKey(Key('journal-item-${reading.readingId}')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Carta fechada'), findsOneWidget);
      expect(find.textContaining('A carta'), findsOneWidget);
      expect(find.textContaining('Fixture 0'), findsNothing);
    },
  );

  testWidgets(
    'Delete requires confirmation, then removes the reading and the list '
    'reflects it immediately without an app restart',
    (tester) async {
      final repo = MemoryReadings();
      final reading = fixtureSession();
      await repo.save(reading);

      await pumpJournal(tester, repo);
      await tester.tap(find.byKey(Key('journal-item-${reading.readingId}')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('journal-delete-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir').last);
      await tester.pumpAndSettle();

      expect(repo.byId.containsKey(reading.readingId), isFalse);
      // Back on the journal list, refreshed with the entry gone.
      expect(find.byKey(const Key('journal-detail')), findsNothing);
      expect(
        find.byKey(Key('journal-item-${reading.readingId}')),
        findsNothing,
      );
      expect(find.text('Nenhuma leitura salva ainda.'), findsOneWidget);
    },
  );

  testWidgets(
    'No reversed-card text or UI exists anywhere in the journal feature',
    (tester) async {
      final repo = MemoryReadings();
      final reading = fixtureSession()
          .placeNext(TablePosition(.2, .3), epoch)
          .reveal('card-0', epoch);
      await repo.save(reading);

      await pumpJournal(tester, repo);
      expect(find.textContaining('invertid', findRichText: true), findsNothing);
      expect(find.textContaining('Invertid', findRichText: true), findsNothing);
      expect(find.textContaining('reversa', findRichText: true), findsNothing);
      expect(find.textContaining('Reversa', findRichText: true), findsNothing);

      await tester.tap(find.byKey(Key('journal-item-${reading.readingId}')));
      await tester.pumpAndSettle();
      expect(find.textContaining('invertid', findRichText: true), findsNothing);
      expect(find.textContaining('reversa', findRichText: true), findsNothing);
    },
  );
}
