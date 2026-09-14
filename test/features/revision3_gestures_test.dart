import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/app/routing/router.dart';
import 'package:tarot_app/features/free_reading/table_geometry.dart';
import 'package:tarot_app/domain/spreads/spread_catalog.dart';

import 'free_reading_test.dart' as support;

import 'package:tarot_app/features/free_reading/reading_controller.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';

Future<void> move(WidgetTester t, String id, Offset to) async {
  final g = await t.startGesture(t.getCenter(find.byKey(Key('card-$id'))));
  await g.moveTo(to);
  await t.pump();
  await g.up();
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'R3 dropping near an empty position stays loose and shows no complement',
    (t) async {
      final c = await support.openReading(t, support.MemoryReadings());
      c.read(routerProvider).go('/reading/spread/SE_SIM_SE_NAO');
      await t.pumpAndSettle();
      final board = t.getRect(find.byKey(const Key('table')));
      final g = TableGeometry(
        board.size,
        SpreadCatalog.byId('SE_SIM_SE_NAO').spread,
      );
      await support.draw(t, board.topLeft + g.complements['sim']!.center);
      final card = support.current(t, 'SE_SIM_SE_NAO').placed.single;
      expect(card.slotId, isNull);
      expect(card.complementOf, isNull);
      expect(find.text('+ complemento'), findsNothing);
      expect(find.text('Carta 1'), findsOneWidget);
    },
  );

  for (final viewport in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 900),
  ]) {
    testWidgets(
      'R3 position labels cannot capture a drag over a loose card $viewport',
      (t) async {
        await t.binding.setSurfaceSize(viewport);
        addTearDown(() => t.binding.setSurfaceSize(null));
        final c = await support.openReading(t, support.MemoryReadings());
        c.read(routerProvider).go('/reading/spread/SE_SIM_SE_NAO');
        await t.pumpAndSettle();
        final board = t.getRect(find.byKey(const Key('table')));
        final g = TableGeometry(
          board.size,
          SpreadCatalog.byId('SE_SIM_SE_NAO').spread,
        );
        final point = g.labels.values.first.center;
        final controller = c.read(
          readingControllerProviderFor('SE_SIM_SE_NAO').notifier,
        );
        await controller.draw(
          TablePosition(point.dx / board.width, point.dy / board.height),
        );
        await t.pumpAndSettle();
        await move(t, 'card-0', board.topLeft + g.staging.center);
        final card = support.current(t, 'SE_SIM_SE_NAO').placed.single;
        expect(
          card.position.y,
          closeTo(g.staging.center.dy / board.height, .001),
        );
      },
    );
    testWidgets(
      'R3 drag fixed card out and back, attach and detach complements $viewport',
      (t) async {
        await t.binding.setSurfaceSize(viewport);
        addTearDown(() => t.binding.setSurfaceSize(null));
        final repo = support.MemoryReadings();
        final c = await support.openReading(t, repo);
        c.read(routerProvider).go('/reading/spread/SE_SIM_SE_NAO');
        await t.pumpAndSettle();
        final board = t.getRect(find.byKey(const Key('table')));
        final g = TableGeometry(
          board.size,
          SpreadCatalog.byId('SE_SIM_SE_NAO').spread,
        );
        final slot = g.cards.entries.first;
        final position = board.topLeft + slot.value.center;
        final staging = board.topLeft + g.staging.center;
        expect(find.text('+ complemento'), findsNothing);
        expect(find.byKey(Key('complement-${slot.key}')), findsNothing);
        await support.draw(t, position);
        expect(find.text('+ complemento'), findsNothing);
        var s = support.current(t, 'SE_SIM_SE_NAO');
        final id = s.placed.single.cardId;
        await t.tap(find.byKey(Key('card-$id')));
        await t.pumpAndSettle();
        await move(t, id, staging);
        expect(
          support.current(t, 'SE_SIM_SE_NAO').placed.single.slotId,
          isNull,
        );
        await move(t, id, position);
        s = support.current(t, 'SE_SIM_SE_NAO');
        expect(s.placed.single.slotId, slot.key);
        expect(s.placed.single.revealed, isTrue);
        expect(s.remaining, 77);
        final complement = board.topLeft + g.complements[slot.key]!.center;
        await support.draw(t, complement);
        await support.draw(
          t,
          position,
        ); // An occupied destination adds, never replaces.
        s = support.current(t, 'SE_SIM_SE_NAO');
        expect(s.complementsFor(slot.key).length, 2);
        expect(s.placed.first.slotId, slot.key);
        final aux = s.complementsFor(slot.key).last;
        expect(find.text('2° complemento'), findsOneWidget);
        await move(t, aux.cardId, staging);
        s = support.current(t, 'SE_SIM_SE_NAO');
        expect(s.complementsFor(slot.key).length, 1);
        expect(s.placed.last.complementOf, isNull);
        expect(repo.saved, isNull);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'R3 manually chosen minor stages and moves to paired minor slot',
    (t) async {
      final c = await support.openReading(t, support.MemoryReadings());
      c.read(routerProvider).go('/reading/spread/CARTA_UNICA');
      await t.pumpAndSettle();
      final provider = readingControllerProviderFor('CARTA_UNICA');
      await c.read(provider.notifier).setPaired(true);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('deck')));
      await t.pumpAndSettle();
      expect(find.textContaining('Esta posição pede'), findsNothing);
      await t.tap(find.text('Menores'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('choose-22')));
      await t.pumpAndSettle();
      final board = t.getRect(find.byKey(const Key('table')));
      final s = support.current(t, 'CARTA_UNICA');
      final g = TableGeometry(board.size, s.spread);
      await t.tapAt(board.topLeft + g.staging.center);
      await t.pumpAndSettle();
      expect(support.current(t, 'CARTA_UNICA').placed.single.cardId, 'card-22');
      expect(support.current(t, 'CARTA_UNICA').placed.single.slotId, isNull);
      final minor = s.spread!.slots.last.slotId;
      await move(t, 'card-22', board.topLeft + g.cards[minor]!.center);
      expect(support.current(t, 'CARTA_UNICA').placed.single.slotId, minor);
      expect(support.current(t, 'CARTA_UNICA').remaining, 77);
    },
  );
  testWidgets('R3 free cards keep visible draw-order titles after movement', (
    t,
  ) async {
    await support.openReading(t, support.MemoryReadings());
    final board = t.getRect(find.byKey(const Key('table')));
    await support.draw(t, board.center);
    await support.draw(t, board.center + const Offset(150, 0));
    await move(t, 'card-0', board.center - const Offset(140, 0));
    expect(find.text('Carta 1'), findsOneWidget);
    expect(find.text('Carta 2'), findsOneWidget);
    expect(find.textContaining('complementar'), findsNothing);
  });
}
