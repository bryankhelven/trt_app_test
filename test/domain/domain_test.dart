import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/domain/cards/tarot_card.dart';
import 'package:tarot_app/domain/decks/tarot_deck.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';
import 'package:tarot_app/domain/readings/reading_history.dart';
import 'package:tarot_app/domain/spreads/spread_catalog.dart';
import 'package:tarot_app/domain/spreads/spread_definition.dart';

import '../support/fixtures.dart';

void main() {
  test('DR-001 card identity validates arcana/suit/rank and is immutable', () {
    expect(
      () => TarotCard(
        cardId: '',
        canonicalName: 'x',
        arcanaType: ArcanaType.major,
        numberOrRank: 0,
        artworkAssetId: 'x',
        editorialContentId: 'x',
      ),
      throwsArgumentError,
    );
    expect(
      () => TarotCard(
        cardId: 'x',
        canonicalName: 'x',
        arcanaType: ArcanaType.major,
        numberOrRank: 22,
        artworkAssetId: 'x',
        editorialContentId: 'x',
      ),
      throwsArgumentError,
    );
    expect(
      () => TarotCard(
        cardId: 'x',
        canonicalName: 'x',
        arcanaType: ArcanaType.minor,
        numberOrRank: 1,
        artworkAssetId: 'x',
        editorialContentId: 'x',
      ),
      throwsArgumentError,
    );
    expect(
      () => fixtureDeck().cards.first.metadata['x'] = 'y',
      throwsUnsupportedError,
    );
  });
  test('DR-002 deck has 78 distinct identities and immutable collections', () {
    final deck = fixtureDeck();
    expect(deck.cardIds.toSet().length, 78);
    expect(() => deck.cards.clear(), throwsUnsupportedError);
    expect(
      () => TarotDeck(
        deckId: 'bad',
        title: 'bad',
        version: '1',
        source: 'fixture',
        provenanceManifest: 'x',
        contentProfile: 'x',
        schemaVersion: 1,
        cards: List.filled(78, deck.cards.first),
      ),
      throwsArgumentError,
    );
    expect(
      () => TarotDeck(
        deckId: 'bad',
        title: 'bad',
        version: '1',
        source: 'fixture',
        provenanceManifest: 'x',
        contentProfile: 'x',
        schemaVersion: 1,
        cards: deck.cards.take(77),
      ),
      throwsArgumentError,
    );
  });
  test('Given session, when drawing, then card begins closed and no identity repeats', () {
    final initial = fixtureSession();
    var s = initial;
    for (var i = 0; i < 78; i++) {
      s = s.placeNext(TablePosition(.5, .5), epoch);
      expect(s.placed.last.drawIndex, i);
      expect(s.placed.last.revealed, isFalse);
    }
    expect(initial.placed, isEmpty);
    expect(s.placed.map((c) => c.cardId).toSet().length, 78);
    expect(s.remaining, 0);
    expect(() => s.placeNext(TablePosition(.1, .2), epoch), throwsStateError);
  });
  test(
    'Given placed card, move preserves identity/reveal and raises z-order',
    () {
      var s = fixtureSession()
          .placeNext(TablePosition(.2, .3), epoch)
          .placeNext(TablePosition(.4, .5), epoch);
      s = s
          .reveal('card-0', epoch)
          .move('card-0', TablePosition(.7, .8), epoch);
      expect(s.placed.first.revealed, isTrue);
      expect(s.placed.first.position, TablePosition(.7, .8));
      expect(s.placed.first.zIndex, greaterThan(s.placed.last.zIndex));
      expect(s.reveal('card-0', epoch), same(s));
      expect(
        () => s.move('missing', TablePosition(0, 0), epoch),
        throwsStateError,
      );
      expect(() => s.reveal('missing', epoch), throwsStateError);
    },
  );
  test('Reject invalid coordinates/order and preserve question/notes', () {
    for (final value in [double.nan, double.infinity, -.01, 1.01]) {
      expect(() => TablePosition(value, .5), throwsArgumentError);
    }
    expect(
      () => ReadingSession.start(
        readingId: 'x',
        deck: fixtureDeck(),
        drawOrder: ['card-0'],
        now: epoch,
      ),
      throwsArgumentError,
    );
    final s = fixtureSession().annotate(
      question: 'Questão privada',
      notes: 'Nota privada',
      now: epoch,
    );
    expect(s.question, 'Questão privada');
    expect(s.notes, 'Nota privada');
    expect(() => s.drawOrder.clear(), throwsUnsupportedError);
  });
  test(
    'DR-007 spread validates unique ordered slots and normalized coordinates',
    () {
      final spread = SpreadDefinition(
        spreadId: 'one',
        nameKey: 'one.name',
        descriptionKey: 'one.description',
        requiredCardCount: 1,
        slots: [
          SpreadSlot(
            slotId: 'center',
            position: TablePosition(.5, .5),
            meaningKey: 'center.meaning',
          ),
        ],
      );
      var s = ReadingSession.start(
        readingId: 'spread',
        deck: fixtureDeck(),
        drawOrder: fixtureDeck().cardIds,
        now: epoch,
        spread: spread,
      );
      expect(
        s.placeNext(TablePosition(.5, .5), epoch).placed.single.slotId,
        isNull,
      );
      s = s.placeNext(TablePosition(.1, .1), epoch, slotId: 'center');
      expect(s.placed.single.position, TablePosition(.5, .5));
      expect(
        () => s.placeNext(TablePosition(.5, .5), epoch, slotId: 'center'),
        throwsStateError,
      );
      expect(
        () => SpreadDefinition(
          spreadId: 'bad',
          nameKey: 'a',
          descriptionKey: 'b',
          requiredCardCount: 2,
          slots: spread.slots,
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'DR-009 draw/move undo redo deterministic; revelation is a history barrier',
    () {
      final history = ReadingHistory(fixtureSession());
      history.apply(history.current.placeNext(TablePosition(.1, .2), epoch));
      history.undo();
      expect(history.current.remaining, 78);
      history.redo();
      expect(history.current.placed.single.cardId, 'card-0');
      history.apply(
        history.current.move('card-0', TablePosition(.7, .8), epoch),
      );
      history.undo();
      expect(history.current.placed.single.position, TablePosition(.1, .2));
      history.redo();
      expect(history.current.placed.single.position, TablePosition(.7, .8));
      history.apply(history.current.reveal('card-0', epoch));
      expect(history.canUndo, isFalse);
      history.undo();
      expect(history.current.placed.single.revealed, isTrue);
    },
  );
  test('M5 spread catalog has the required v1 set with valid, unique, in-range slots', () {
    final modes = SpreadCatalog.modes;
    expect(modes.map((m) => m.id).toSet().length, modes.length);
    expect(modes.map((m) => m.id).toSet(), {
      'FREE',
      'CARTA_UNICA',
      'PASSADO_PRESENTE_FUTURO',
      'SITUACAO_OBSTACULO_CONSELHO',
      'RELACAO',
      'FERRADURA',
      'CRUZ_CELTICA',
      'SE_SIM_SE_NAO',
      'QUATRO_ELEMENTOS',
      'CRUZ_HERMETICA',
    });
    final required = {
      'CARTA_UNICA': 1,
      'PASSADO_PRESENTE_FUTURO': 3,
      'SITUACAO_OBSTACULO_CONSELHO': 3,
      'RELACAO': 5,
      'FERRADURA': 7,
      'CRUZ_CELTICA': 10,
      'SE_SIM_SE_NAO': 2,
      'QUATRO_ELEMENTOS': 4,
      'CRUZ_HERMETICA': 11,
    };
    for (final mode in modes.where((m) => m.spread != null)) {
      final spread = mode.spread!;
      expect(spread.requiredCardCount, required[spread.spreadId]);
      expect(spread.slots.length, spread.requiredCardCount);
      expect(
        spread.slots.map((s) => s.slotId).toSet().length,
        spread.slots.length,
      );
      for (final slot in spread.slots) {
        expect(slot.position.x, inInclusiveRange(0.0, 1.0));
        expect(slot.position.y, inInclusiveRange(0.0, 1.0));
        expect(slot.meaningKey, isNotEmpty);
      }
    }
  });
  test(
    'A predefined spread fills its labelled slots in order without duplicates',
    () {
      final session = ReadingSession.start(
        readingId: 'r-spread',
        deck: fixtureDeck(),
        drawOrder: fixtureDeck().cardIds,
        now: epoch,
        spread: SpreadCatalog.passadoPresenteFuturo,
      );
      var s = session;
      for (final slot in SpreadCatalog.passadoPresenteFuturo.slots) {
        s = s.placeNext(slot.position, epoch, slotId: slot.slotId);
      }
      expect(s.placed.length, 3);
      expect(s.placed.map((c) => c.cardId).toSet().length, 3);
      expect(
        s.placed.map((c) => c.slotId).toSet(),
        SpreadCatalog.passadoPresenteFuturo.slots
            .map((sl) => sl.slotId)
            .toSet(),
      );
      expect(s.remaining, 75);
    },
  );
}
