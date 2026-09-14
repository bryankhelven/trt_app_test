import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/domain/spreads/spread_catalog.dart';
import 'package:tarot_app/features/free_reading/table_geometry.dart';
import 'package:tarot_app/features/free_reading/reading_controller.dart';
import 'package:tarot_app/app/routing/router.dart';

import 'free_reading_test.dart' as support;

void main() {
  test('R2 all structural positions fit both orientations; crosses retain geometry', () {
    for (final size in [
      const Size(390, 620),
      const Size(844, 240),
      const Size(1280, 740),
    ]) {
      for (final mode in SpreadCatalog.modes.where((m) => m.spread != null)) {
        for (final spread in [
          mode.spread!,
          SpreadCatalog.withPairs(mode.spread!),
        ]) {
          final g = TableGeometry(size, spread);
          for (final entry in g.cards.entries) {
            expect(
              (Offset.zero & size).contains(entry.value.topLeft),
              isTrue,
              reason: '${mode.id} ${entry.key} $size',
            );
            expect(
              (Offset.zero & size).contains(entry.value.bottomRight),
              isTrue,
            );
            expect(entry.value.overlaps(g.deck), isFalse);
          }
        }
      }
      for (final mode in SpreadCatalog.modes.where((m) => m.spread != null)) {
        for (final spread in [
          mode.spread!,
          SpreadCatalog.withPairs(mode.spread!),
        ]) {
          final g = TableGeometry(size, spread);
          expect(
            g.staging.height,
            greaterThanOrEqualTo(g.width * 5 / 3),
            reason: 'Staging ${mode.id} $size',
          );
          for (final entry in g.complements.entries) {
            expect(
              (Offset.zero & size).contains(entry.value.topLeft),
              isTrue,
              reason: 'Complement ${mode.id} ${entry.key} $size',
            );
            expect(
              (Offset.zero & size).contains(entry.value.bottomRight),
              isTrue,
            );
            expect(entry.value.overlaps(g.deck), isFalse);
            for (final core in g.cards.values) {
              expect(
                entry.value.overlaps(core),
                isFalse,
                reason:
                    'Complement must have space: ${mode.id} ${entry.key} $size',
              );
            }
          }
        }
      }
      final g = TableGeometry(size, SpreadCatalog.cruzCeltica);
      expect(g.cards['coroa']!.center.dx, g.cards['fundamento']!.center.dx);
      expect(
        g.cards['passado_recente']!.center.dy,
        g.cards['futuro_proximo']!.center.dy,
      );
      expect(
        g.cards['desafio']!.width,
        greaterThan(g.cards['desafio']!.height),
      );
      expect(g.cards['desafio']!.overlaps(g.cards['situacao']!), isTrue);
    }
  });
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 900),
  ]) {
    testWidgets('R2 every board fits $size without replacing its geometry', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = await support.openReading(tester, support.MemoryReadings());
      for (final mode in SpreadCatalog.modes.where((m) => m.spread != null)) {
        c.read(routerProvider).go('/reading/spread/${mode.id}');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('spread-lines')), findsOneWidget);
        final controller = c.read(
          readingControllerProviderFor(mode.id).notifier,
        );
        for (final slot in mode.spread!.slots) {
          await controller.draw(slot.position, slotId: slot.slotId);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final table = tester.getRect(find.byKey(const Key('table')));
        for (final card in support.current(tester, mode.id).placed) {
          final rect = tester.getRect(find.byKey(Key('card-${card.cardId}')));
          expect(table.contains(rect.topLeft), isTrue);
          expect(table.contains(rect.bottomRight), isTrue);
        }
      }
    });
  }
  testWidgets('R2 table usable at 200 percent text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = await support.openReading(tester, support.MemoryReadings());
    c.read(routerProvider).go('/reading/spread/CRUZ_CELTICA');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('save-reading')), findsOneWidget);
  });
}
