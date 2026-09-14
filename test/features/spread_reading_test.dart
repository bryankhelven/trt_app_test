import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarot_app/app/app.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/application/ports/reading_repository.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';

import '../support/fixtures.dart';
import 'free_reading_test.dart' show current, OrderedRandom;

class MemoryReadings implements ReadingRepository {
  final Map<String, ReadingSession> byMode = {};
  @override
  Future<void> save(ReadingSession session) async {
    byMode[session.spreadId] = session;
  }

  @override
  Future<ReadingSession?> active({String mode = 'FREE'}) async => byMode[mode];
  @override
  Future<ReadingSession?> read(String id) async =>
      byMode.values.where((s) => s.readingId == id).firstOrNull;
  @override
  Future<List<ReadingSession>> list() async => byMode.values.toList();
  @override
  Future<void> delete(String id) async =>
      byMode.removeWhere((_, s) => s.readingId == id);
}

void main() {
  testWidgets(
    'Passado/Presente/Futuro fills its three labelled slots and keeps its '
    'own active session separate from Tiragem Livre',
    (tester) async {
      final repo = MemoryReadings();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingRepositoryProvider.overrideWithValue(repo),
            deckProvider.overrideWithValue(fixtureDeck()),
            randomProvider.overrideWithValue(OrderedRandom()),
          ],
          child: const TarotApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Passado / Presente / Futuro'));
      await tester.tap(find.text('Passado / Presente / Futuro'));
      await tester.pumpAndSettle();
      expect(find.text('Passado / Presente / Futuro'), findsWidgets);
      expect(find.text('Passado'), findsOneWidget);
      expect(find.text('Presente'), findsOneWidget);
      expect(find.text('Futuro'), findsOneWidget);

      final deck = find.byKey(const Key('deck'));
      expect(current(tester, 'PASSADO_PRESENTE_FUTURO').placed, isEmpty);
      for (final slot in ['passado', 'presente', 'futuro']) {
        await tester.ensureVisible(deck);
        await tester.tap(deck);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('choose-0')));
        await tester.pumpAndSettle();
        final target = find.byKey(Key('slot-$slot'));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('3/3 posições principais'), findsOneWidget);
      // A fourth card is allowed outside the structural slots.
      await tester.ensureVisible(deck);
      final destination =
          tester.getTopLeft(find.byKey(const Key('table'))) +
          const Offset(350, 105);
      final gesture = await tester.startGesture(tester.getCenter(deck));
      await gesture.moveTo(destination);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(current(tester, 'PASSADO_PRESENTE_FUTURO').placed.length, 4);
      final placed = current(tester, 'PASSADO_PRESENTE_FUTURO').placed;
      expect(placed.length, 4);
      expect(placed.map((c) => c.cardId).toSet().length, 4);

      // Reveal then open details for the first placed card.
      final firstCard = find.byKey(Key('card-${placed.first.cardId}'));
      await tester.ensureVisible(firstCard);
      await tester.tap(firstCard);
      await tester.pumpAndSettle();
      await tester.ensureVisible(firstCard);
      await tester.tap(firstCard);
      await tester.pumpAndSettle();
      expect(find.text('Sobre a carta'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Free Reading has its own untouched active session.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiragem Livre'));
      await tester.pumpAndSettle();
      expect(repo.byMode, isEmpty);
      expect(current(tester).placed, isEmpty);
    },
  );
}
