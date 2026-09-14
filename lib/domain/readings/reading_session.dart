import '../cards/tarot_card.dart';
import '../decks/tarot_deck.dart';
import '../spreads/spread_definition.dart';
export '../spreads/spread_definition.dart' show TablePosition;

class PlacedCard {
  PlacedCard({
    required this.cardId,
    required this.drawIndex,
    required this.position,
    required this.revealed,
    required this.zIndex,
    this.slotId,
    this.complementOf,
    this.associationOrder,
  }) {
    requireText(cardId, 'cardId');
    if (drawIndex < 0 ||
        zIndex < 0 ||
        (slotId != null && complementOf != null) ||
        (complementOf == null) != (associationOrder == null) ||
        (associationOrder != null && associationOrder! < 0)) {
      throw ArgumentError('Invalid card indices');
    }
  }
  final String cardId;
  final int drawIndex, zIndex;
  final TablePosition position;
  final bool revealed;
  final String? slotId, complementOf;
  final int? associationOrder;
  PlacedCard copyWith({
    TablePosition? position,
    bool? revealed,
    int? zIndex,
    bool detach = false,
    String? slotId,
    String? complementOf,
    int? associationOrder,
  }) => PlacedCard(
    cardId: cardId,
    drawIndex: drawIndex,
    position: position ?? this.position,
    revealed: this.revealed || (revealed ?? false),
    zIndex: zIndex ?? this.zIndex,
    slotId: detach ? slotId : slotId ?? this.slotId,
    complementOf: detach ? complementOf : complementOf ?? this.complementOf,
    associationOrder: detach
        ? associationOrder
        : associationOrder ?? this.associationOrder,
  );
}

class ReadingSession {
  ReadingSession({
    required this.readingId,
    required this.createdAt,
    required this.updatedAt,
    required this.deckId,
    required this.deckVersion,
    required this.contentVersion,
    required Iterable<String> drawOrder,
    required Iterable<PlacedCard> placed,
    this.spread,
    this.question = '',
    this.notes = '',
    this.persistenceVersion = 1,
  }) : drawOrder = List.unmodifiable(drawOrder),
       placed = List.unmodifiable(placed) {
    for (final value in [readingId, deckId, deckVersion, contentVersion]) {
      requireText(value, 'session metadata');
    }
    if (persistenceVersion != 1 ||
        updatedAt.isBefore(createdAt) ||
        this.drawOrder.length != 78 ||
        this.drawOrder.toSet().length != 78 ||
        this.drawOrder.any((id) => id.isEmpty) ||
        this.placed.length > 78) {
      throw ArgumentError('Invalid session metadata or draw order');
    }
    final slots = <String>{};
    final zs = <int>{};
    final associations = <int>{};
    for (var i = 0; i < this.placed.length; i++) {
      final card = this.placed[i];
      if (card.drawIndex != i ||
          card.cardId != this.drawOrder[i] ||
          !zs.add(card.zIndex)) {
        throw ArgumentError(
          'Placed cards must match draw prefix with unique z-order',
        );
      }
      if (card.complementOf != null &&
          (!(spread?.slots.any(
                    (s) => positionId(s.slotId) == card.complementOf,
                  ) ??
                  false) ||
              !associations.add(card.associationOrder!))) {
        throw ArgumentError('Invalid complement association');
      }
      if (spread == null) {
        if (card.slotId != null) {
          throw ArgumentError('Free card cannot occupy a spread slot');
        }
      } else if (card.slotId != null) {
        if (!spread!.slots.any(
              (s) => s.slotId == card.slotId && s.position == card.position,
            ) ||
            !slots.add(card.slotId!)) {
          throw ArgumentError('Invalid spread placement');
        }
      }
    }
  }
  factory ReadingSession.start({
    required String readingId,
    required TarotDeck deck,
    required Iterable<String> drawOrder,
    required DateTime now,
    SpreadDefinition? spread,
  }) {
    final order = drawOrder.toList();
    if (order.length != 78 ||
        order.toSet().length != 78 ||
        !order.toSet().containsAll(deck.cardIds)) {
      throw ArgumentError('Draw order must be a deck permutation');
    }
    return ReadingSession(
      readingId: readingId,
      createdAt: now,
      updatedAt: now,
      deckId: deck.deckId,
      deckVersion: deck.version,
      contentVersion: deck.contentProfile,
      drawOrder: order,
      placed: const [],
      spread: spread,
    );
  }
  final String readingId, deckId, deckVersion, contentVersion, question, notes;
  final DateTime createdAt, updatedAt;
  final int persistenceVersion;
  final List<String> drawOrder;
  final List<PlacedCard> placed;
  final SpreadDefinition? spread;
  String get spreadId => spread?.spreadId ?? 'FREE';
  int get remaining => drawOrder.length - placed.length;
  int get nextZ => placed.fold(-1, (z, c) => c.zIndex > z ? c.zIndex : z) + 1;

  static String positionId(String slotId) => slotId.split(':').first;
  List<PlacedCard> complementsFor(String positionId) =>
      placed.where((c) => c.complementOf == positionId).toList()
        ..sort((a, b) => a.associationOrder!.compareTo(b.associationOrder!));
  int complementNumber(PlacedCard card) => card.complementOf == null
      ? 0
      : complementsFor(card.complementOf!)
                .indexWhere((c) => c.cardId == card.cardId) +
            1;
  String positionLabel(String id) => spread!.slots
      .firstWhere((s) => positionId(s.slotId) == id)
      .meaningKey
      .split(' · ')
      .first;
  String cardLabel(PlacedCard card) {
    if (card.complementOf != null) {
      return '${complementNumber(card)}° complemento · ${positionLabel(card.complementOf!)}';
    }
    return spread?.slots
            .where((s) => s.slotId == card.slotId)
            .firstOrNull
            ?.meaningKey ??
        'Carta ${card.drawIndex + 1}';
  }

  int get _nextAssociation =>
      placed.fold(
        -1,
        (n, c) => (c.associationOrder ?? -1) > n ? c.associationOrder! : n,
      ) +
      1;
  void _validateDestination(
    String? slotId,
    String? complementOf, {
    String? moving,
  }) {
    if (slotId != null && complementOf != null) {
      throw StateError('Escolha um único destino.');
    }
    if (slotId != null &&
        (!(spread?.slots.any((s) => s.slotId == slotId) ?? false) ||
            placed.any((c) => c.slotId == slotId && c.cardId != moving))) {
      throw StateError('Posição indisponível.');
    }
    if (complementOf != null &&
        !(spread?.slots.any((s) => positionId(s.slotId) == complementOf) ??
            false)) {
      throw StateError('Posição do complemento inexistente.');
    }
  }

  ReadingSession _copy({
    List<PlacedCard>? placed,
    required DateTime now,
    String? question,
    String? notes,
    List<String>? drawOrder,
  }) => ReadingSession(
    readingId: readingId,
    createdAt: createdAt,
    updatedAt: now.isBefore(createdAt) ? createdAt : now,
    deckId: deckId,
    deckVersion: deckVersion,
    contentVersion: contentVersion,
    drawOrder: drawOrder ?? this.drawOrder,
    placed: placed ?? this.placed,
    spread: spread,
    question: question ?? this.question,
    notes: notes ?? this.notes,
  );
  ReadingSession placeNext(
    TablePosition position,
    DateTime now, {
    String? slotId,
    String? complementOf,
  }) {
    if (remaining == 0) throw StateError('Deck exhausted');
    _validateDestination(slotId, complementOf);
    if (slotId != null) {
      position = spread!.slots.singleWhere((s) => s.slotId == slotId).position;
    }
    return _copy(
      now: now,
      placed: [
        ...placed,
        PlacedCard(
          cardId: drawOrder[placed.length],
          drawIndex: placed.length,
          position: position,
          revealed: false,
          zIndex: nextZ,
          slotId: slotId,
          complementOf: complementOf,
          associationOrder: complementOf == null ? null : _nextAssociation,
        ),
      ],
    );
  }

  /// Index is relative to the remaining, face-down pile. Selection is atomic:
  /// invalid destinations cannot consume or reorder any card.
  ReadingSession chooseCard(
    int index,
    TablePosition position,
    DateTime now, {
    String? slotId,
    String? complementOf,
  }) {
    RangeError.checkValidIndex(index, drawOrder.skip(placed.length).toList());
    final rest = drawOrder.skip(placed.length).toList();
    final selected = rest.removeAt(index);
    return reorderRemaining(
      [selected, ...rest],
      now,
    ).placeNext(position, now, slotId: slotId, complementOf: complementOf);
  }

  ReadingSession move(
    String cardId,
    TablePosition position,
    DateTime now, {
    String? slotId,
    String? complementOf,
  }) {
    final card = _card(cardId);
    _validateDestination(slotId, complementOf, moving: cardId);
    if (slotId != null) {
      position = spread!.slots.singleWhere((s) => s.slotId == slotId).position;
    }
    return _copy(
      now: now,
      placed: [
        for (final c in placed)
          c.cardId == cardId
              ? c.copyWith(
                  position: position,
                  zIndex: nextZ,
                  detach: true,
                  slotId: slotId,
                  complementOf: complementOf,
                  associationOrder: complementOf == null
                      ? null
                      : card.complementOf == complementOf
                      ? card.associationOrder
                      : _nextAssociation,
                )
              : c,
      ],
    );
  }

  PlacedCard _card(String id) {
    final matches = placed.where((c) => c.cardId == id);
    if (matches.isEmpty) throw StateError('Card not on table');
    return matches.single;
  }

  ReadingSession reveal(String cardId, DateTime now) {
    if (_card(cardId).revealed) return this;
    return _copy(
      now: now,
      placed: [
        for (final c in placed)
          c.cardId == cardId ? c.copyWith(revealed: true) : c,
      ],
    );
  }

  ReadingSession annotate({
    required String question,
    required String notes,
    required DateTime now,
  }) => _copy(now: now, question: question, notes: notes);
  ReadingSession reorderRemaining(List<String> remainingOrder, DateTime now) {
    final expected = drawOrder.skip(placed.length).toSet();
    if (remainingOrder.length != remaining ||
        remainingOrder.toSet().length != remaining ||
        !expected.containsAll(remainingOrder)) {
      throw ArgumentError('Must preserve remaining identities');
    }
    return _copy(
      now: now,
      drawOrder: [...drawOrder.take(placed.length), ...remainingOrder],
    );
  }
}
