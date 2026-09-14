import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/app/app.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/application/ports/reading_repository.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';
import 'package:tarot_app/features/free_reading/reading_controller.dart';

import '../support/fixtures.dart';

import 'package:tarot_app/domain/randomization/shuffle.dart';
import 'package:tarot_app/app/routing/router.dart';

class MemoryReadings implements ReadingRepository {
  ReadingSession? saved;
  bool fail = false;
  @override
  Future<void> save(ReadingSession session) async {
    if (fail) {
      throw StateError('Storage unavailable');
    }
    saved = session;
  }

  @override
  Future<ReadingSession?> active({String mode = 'FREE'}) async => saved;
  @override
  Future<ReadingSession?> read(String id) async =>
      saved?.readingId == id ? saved : null;
  @override
  Future<List<ReadingSession>> list() async => [?saved];
  @override
  Future<void> delete(String id) async {
    saved = null;
  }
}

Future<ProviderContainer> openReading(
  WidgetTester tester,
  MemoryReadings repo,
) async {
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
  await tester.ensureVisible(find.byKey(const Key('start-free')));
  await tester.tap(find.byKey(const Key('start-free')));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(TarotApp)));
}

Future<void> draw(WidgetTester tester, Offset destination) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const Key('deck'))),
  );
  await gesture.moveTo(destination);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

class OrderedRandom implements RandomSource {
  int counter = 0;
  @override
  int nextInt(int max) => max == 256 ? (counter++ % max) : max - 1;
}

ReadingSession current(WidgetTester tester, [String mode = 'FREE']) =>
    ProviderScope.containerOf(tester.element(find.byType(TarotApp)))
        .read(readingControllerProviderFor(mode))
        .requireValue
        .session;

void main() {
  testWidgets(
    'AC-FREE-001/002/007 deck top right, drag center and cancel conserve pile',
    (tester) async {
      final repo = MemoryReadings();
      await openReading(tester, repo);
      final table = tester.getRect(find.byKey(const Key('table')));
      final deck = tester.getRect(find.byKey(const Key('deck')));
      expect(deck.center.dx, greaterThan(table.center.dx));
      expect(deck.center.dy, lessThan(table.center.dy));
      expect(deck.width, greaterThan(25));
      final g = await tester.startGesture(deck.center);
      await g.moveTo(table.center);
      await tester.pump();
      expect(
        tester.getCenter(find.byKey(const Key('drag-feedback'))),
        table.center,
      );
      await g.cancel();
      await tester.pumpAndSettle();
      expect(current(tester).remaining, 78);
      final outside = await tester.startGesture(deck.center);
      await outside.moveTo(const Offset(-20, -20));
      await tester.pump();
      await outside.up();
      await tester.pumpAndSettle();
      expect(current(tester).remaining, 78);
      await draw(tester, table.center);
      expect(current(tester).remaining, 77);
      expect(current(tester).placed.single.revealed, isFalse);
    },
  );
  testWidgets(
    'AC-FREE-003/004 reveal then global details; dragging never taps',
    (tester) async {
      final repo = MemoryReadings();
      await openReading(tester, repo);
      final center = tester.getCenter(find.byKey(const Key('table')));
      await draw(tester, center);
      final card = find.byKey(const Key('card-card-0'));
      await tester.drag(card, const Offset(-80, 40));
      await tester.pumpAndSettle();
      expect(current(tester).placed.single.revealed, isFalse);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(current(tester).placed.single.revealed, isTrue);
      expect(find.byType(Dialog), findsNothing);
      await tester.drag(card, const Offset(100, 40));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await draw(tester, center + const Offset(-120, 0));
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.text('Conteúdo editorial em preparação para este baralho.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Fechar informações'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(current(tester).placed.length, 2);
    },
  );
  testWidgets(
    'R2 rotation preserves memory; exit drops draft; explicit save survives',
    (tester) async {
      final repo = MemoryReadings();
      final container = await openReading(tester, repo);
      await draw(tester, tester.getCenter(find.byKey(const Key('table'))));
      await tester.tap(find.byKey(const Key('card-card-0')));
      await tester.pumpAndSettle();
      final before = current(tester);
      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpAndSettle();
        expect(current(tester), same(before));
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(find.byKey(const Key('card-card-0')));
        final table = tester.getRect(find.byKey(const Key('table')));
        expect(
          table.contains(rect.topLeft) && table.contains(rect.bottomRight),
          isTrue,
        );
      }
      expect(repo.saved, isNull);
      await tester.tap(find.byKey(const Key('save-reading')));
      await tester.pumpAndSettle();
      expect(repo.saved, same(before));
      container.read(routerProvider).go('/');
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/reading/free');
      await tester.pumpAndSettle();
      expect(current(tester).placed, isEmpty);
      expect(repo.saved, same(before));
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('Save failure keeps reading usable and offers explicit retry', (
    tester,
  ) async {
    final repo = MemoryReadings();
    final container = await openReading(tester, repo);
    repo.fail = true;
    await draw(tester, tester.getCenter(find.byKey(const Key('table'))));
    expect(
      container
          .read(readingControllerProvider)
          .requireValue
          .session
          .placed
          .length,
      1,
    );
    await tester.tap(find.byKey(const Key('save-reading')));
    await tester.pumpAndSettle();
    expect(find.text('Tentar salvar'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Tentar salvar'));
    await tester.pumpAndSettle();
    expect(repo.saved!.placed.length, 1);
    expect(find.text('Tentar salvar'), findsNothing);
  });
  testWidgets('78 draws exhaust the deck without duplicate fallback', (
    tester,
  ) async {
    final repo = MemoryReadings();
    final c = await openReading(tester, repo);
    for (var i = 0; i < 77; i++) {
      await c
          .read(readingControllerProvider.notifier)
          .draw(TablePosition(.5, .5));
    }
    await tester.pumpAndSettle();
    await draw(tester, tester.getCenter(find.byKey(const Key('table'))));
    expect(current(tester).remaining, 0);
    expect(find.text('Baralho esgotado'), findsOneWidget);
    expect(current(tester).placed.map((c) => c.cardId).toSet().length, 78);
  });
  testWidgets('Shuffle and cut menu actions reorder the remaining pile and '
      'confirm visibly', (tester) async {
    final repo = MemoryReadings();
    await openReading(tester, repo);
    final before = current(tester).drawOrder;
    await tester.tap(find.byTooltip('Opções da mesa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Embaralhar restantes'));
    await tester.pumpAndSettle();
    expect(find.text('Baralho restante embaralhado.'), findsOneWidget);
    expect(current(tester).drawOrder.toSet(), before.toSet());

    await tester.tap(find.byTooltip('Opções da mesa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cortar ao meio'));
    await tester.pumpAndSettle();
    expect(find.text('Baralho restante cortado ao meio.'), findsOneWidget);
    expect(current(tester).drawOrder.toSet(), before.toSet());
  });
}
