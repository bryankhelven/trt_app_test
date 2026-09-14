import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/domain/spreads/spread_catalog.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';
import 'package:tarot_app/features/free_reading/reading_controller.dart';

import 'features/free_reading_test.dart' show MemoryReadings;
import 'support/fixtures.dart';

import 'package:tarot_app/infrastructure/persistence/reading_codec.dart';

void main() {
  test(
    'R2 explicit save is the only write; new reading keeps saved snapshot',
    () async {
      final repo = MemoryReadings();
      final c = ProviderContainer(
        overrides: [
          readingRepositoryProvider.overrideWithValue(repo),
          deckProvider.overrideWithValue(fixtureDeck()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(readingControllerProvider.future);
      final controller = c.read(readingControllerProvider.notifier);
      await controller.draw(TablePosition(.5, .5));
      await controller.annotate('Pergunta', 'Notas');
      expect(repo.saved, isNull);
      await controller.saveExplicitly();
      final saved = repo.saved!;
      await controller.reveal(saved.placed.single.cardId);
      expect(repo.saved, same(saved));
      await controller.newReading();
      expect(
        c.read(readingControllerProvider).requireValue.session.placed,
        isEmpty,
      );
      expect(repo.saved, same(saved));
      c.invalidate(readingControllerProvider);
      expect(
        (await c.read(readingControllerProvider.future)).session.placed,
        isEmpty,
      );
    },
  );
  test('R2 all paired structures round trip with each required arcana and no duplicates', () async {
    for (final mode in SpreadCatalog.modes.where((m) => m.spread != null)) {
      final c = ProviderContainer(
        overrides: [
          readingRepositoryProvider.overrideWithValue(MemoryReadings()),
          deckProvider.overrideWithValue(fixtureDeck()),
        ],
      );
      final p = readingControllerProviderFor(mode.id);
      await c.read(p.future);
      final controller = c.read(p.notifier);
      await controller.annotate('Pergunta preservada', 'Nota');
      await controller.setPaired(true);
      expect(c.read(p).requireValue.session.question, 'Pergunta preservada');
      final spread = c.read(p).requireValue.session.spread!;
      for (final slot in spread.slots) {
        final session = c.read(p).requireValue.session;
        final index = session.drawOrder
            .skip(session.placed.length)
            .toList()
            .indexWhere(
              (id) => fixtureDeck().card(id).arcanaType == slot.requiredArcana,
            );
        await controller.draw(slot.position, slotId: slot.slotId, index: index);
      }
      final result = c.read(p).requireValue.session;
      expect(result.placed.length, mode.spread!.slots.length * 2);
      expect(
        result.placed.map((x) => x.cardId).toSet().length,
        result.placed.length,
      );
      final decoded = ReadingCodec.decode(ReadingCodec.encode(result));
      for (final card in decoded.placed) {
        final slot = decoded.spread!.slots.singleWhere(
          (s) => s.slotId == card.slotId,
        );
        expect(fixtureDeck().card(card.cardId).arcanaType, slot.requiredArcana);
      }
      c.dispose();
    }
  });
  test('R2 requested catalog and 11 Hermetic positions', () {
    expect(SpreadCatalog.byId('SE_SIM_SE_NAO').spread!.slots.length, 2);
    expect(SpreadCatalog.byId('QUATRO_ELEMENTOS').spread!.slots.length, 4);
    expect(SpreadCatalog.byId('CRUZ_HERMETICA').spread!.slots.length, 11);
  });
  test('R2 each paired position has one major and one minor', () async {
    final repo = MemoryReadings();
    final c = ProviderContainer(
      overrides: [
        readingRepositoryProvider.overrideWithValue(repo),
        deckProvider.overrideWithValue(fixtureDeck()),
      ],
    );
    addTearDown(c.dispose);
    final p = readingControllerProviderFor('CARTA_UNICA');
    await c.read(p.future);
    final controller = c.read(p.notifier);
    await controller.setPaired(true);
    final slots = c.read(p).requireValue.session.spread!.slots;
    expect(slots.length, 2);
    final s = c.read(p).requireValue.session;
    final wrong = s.drawOrder.indexWhere(
      (id) => fixtureDeck().card(id).numberOrRank == 1 && id == 'card-22',
    );
    expect(
      () => controller.draw(
        slots.first.position,
        slotId: slots.first.slotId,
        index: wrong,
      ),
      throwsStateError,
    );
  });
}
