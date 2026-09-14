import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';
import 'package:tarot_app/domain/spreads/spread_catalog.dart';
import 'package:tarot_app/infrastructure/persistence/reading_codec.dart';

import '../support/fixtures.dart';

void main() {
  for (final mode in SpreadCatalog.modes.where((m) => m.spread != null)) {
    test('BR-HARD-003/007 ${mode.id}: core slots plus auxiliary until 78', () {
      var s = ReadingSession.start(
        readingId: 'r',
        deck: fixtureDeck(),
        drawOrder: fixtureDeck().cardIds,
        now: epoch,
        spread: mode.spread,
      );
      expect(s.placed, isEmpty);
      for (final slot in mode.spread!.slots) {
        s = s.placeNext(slot.position, epoch, slotId: slot.slotId);
      }
      while (s.remaining > 0) {
        s = s.placeNext(TablePosition(.2, .8), epoch);
      }
      expect(s.placed.length, 78);
      expect(
        s.placed.where((c) => c.slotId == null).length,
        78 - mode.spread!.requiredCardCount,
      );
      expect(s.placed.map((c) => c.cardId).toSet().length, 78);
      final restored = ReadingCodec.decode(ReadingCodec.encode(s));
      expect(restored.placed.length, 78);
      expect(restored.drawOrder, s.drawOrder);
      final last = s.placed.last.cardId;
      s = s.move(last, TablePosition(.3, .7), epoch);
      expect(s.placed.last.position, TablePosition(.3, .7));
    });
  }
  test(
    'RF-018 choose specific hidden index preserves rest and round trips',
    () {
      final initial = fixtureSession();
      final s = initial.chooseCard(17, TablePosition(.2, .3), epoch);
      expect(s.placed.single.cardId, 'card-17');
      expect(s.placed.single.revealed, isFalse);
      expect(
        s.drawOrder.skip(1),
        initial.drawOrder.where((id) => id != 'card-17'),
      );
      expect(initial.remaining, 78);
      expect(
        ReadingCodec.decode(ReadingCodec.encode(s)).drawOrder,
        s.drawOrder,
      );
      expect(
        () => initial.chooseCard(78, TablePosition(.5, .5), epoch),
        throwsRangeError,
      );
    },
  );
}
