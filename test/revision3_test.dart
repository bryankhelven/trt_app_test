import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';
import 'package:tarot_app/domain/readings/reading_history.dart';
import 'package:tarot_app/domain/spreads/spread_catalog.dart';
import 'package:tarot_app/infrastructure/persistence/reading_codec.dart';

import 'support/fixtures.dart';

ReadingSession fixed({bool paired = false}) => ReadingSession.start(
  readingId: 'r3',
  deck: fixtureDeck(),
  drawOrder: fixtureDeck().cardIds,
  now: epoch,
  spread: paired
      ? SpreadCatalog.withPairs(SpreadCatalog.cruzCeltica)
      : SpreadCatalog.cruzCeltica,
);
void main() {
  test('R3 chosen card stages, enters slot, leaves revealed, and returns unchanged', () {
    var s = fixed().chooseCard(12, TablePosition(.2, .2), epoch);
    final id = s.placed.single.cardId;
    s = s
        .move(id, TablePosition(.3, .3), epoch, slotId: 'situacao')
        .reveal(id, epoch);
    s = s.move(id, TablePosition(.1, .1), epoch);
    expect(s.placed.single.slotId, isNull);
    expect(s.placed.single.revealed, isTrue);
    s = s.move(id, TablePosition(.3, .3), epoch, slotId: 'situacao');
    expect(s.placed.single.slotId, 'situacao');
    expect(s.placed.single.drawIndex, 0);
    expect(s.remaining, 77);
    expect(s.drawOrder.first, 'card-12');
  });
  test(
    'R3 complements ordered per logical position and renumber after detaching',
    () {
      var s = fixed();
      for (var i = 0; i < 4; i++) {
        s = s.placeNext(TablePosition(.2, .2), epoch);
      }
      s = s.move(
        'card-2',
        TablePosition(.3, .3),
        epoch,
        complementOf: 'situacao',
      );
      s = s.move(
        'card-0',
        TablePosition(.3, .3),
        epoch,
        complementOf: 'situacao',
      );
      s = s.move(
        'card-1',
        TablePosition(.3, .3),
        epoch,
        complementOf: 'desafio',
      );
      expect(s.cardLabel(s.placed[2]), '1° complemento · Situação presente');
      expect(s.complementsFor('situacao').map((c) => c.cardId), [
        'card-2',
        'card-0',
      ]);
      s = s.move('card-2', TablePosition(.1, .1), epoch);
      expect(s.complementNumber(s.placed[0]), 1);
      expect(s.cardLabel(s.placed[2]), 'Carta 3');
      final history = ReadingHistory(s);
      history.apply(
        s.move('card-0', TablePosition(.1, .1), epoch, complementOf: 'desafio'),
      );
      expect(history.current.complementNumber(history.current.placed[0]), 2);
      history.undo();
      expect(history.current.placed[0].complementOf, 'situacao');
      history.redo();
      final decoded = ReadingCodec.decode(ReadingCodec.encode(history.current));
      expect(decoded.complementsFor('desafio').map((c) => c.cardId), [
        'card-1',
        'card-0',
      ]);
    },
  );
  test('R3 paired slots share complements; invalid associations rejected atomically', () {
    final s = fixed(paired: true)
        .placeNext(TablePosition(.2, .2), epoch, complementOf: 'situacao');
    expect(s.placed.single.complementOf, 'situacao');
    expect(
      () => s.move(
        'card-0',
        TablePosition(.2, .2),
        epoch,
        complementOf: 'missing',
      ),
      throwsStateError,
    );
    expect(
      () => fixtureSession().placeNext(
        TablePosition(.2, .2),
        epoch,
        complementOf: 'situacao',
      ),
      throwsStateError,
    );
    expect(
      () => s.move(
        'card-0',
        TablePosition(.2, .2),
        epoch,
        slotId: 'situacao:major',
        complementOf: 'situacao',
      ),
      throwsStateError,
    );
  });
  test(
    'R3 old snapshots decode and free numbering is draw order, not z-order',
    () {
      var s = fixtureSession()
          .placeNext(TablePosition(.2, .2), epoch)
          .placeNext(TablePosition(.3, .3), epoch);
      s = s.move('card-0', TablePosition(.6, .6), epoch);
      expect(s.cardLabel(s.placed.first), 'Carta 1');
      final encoded = ReadingCodec.encode(s);
      expect(encoded.contains('complementOf'), isFalse);
      expect(ReadingCodec.decode(encoded).placed.first.complementOf, isNull);
    },
  );
}
