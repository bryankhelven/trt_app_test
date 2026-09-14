import '../cards/tarot_card.dart';

/// Normalized table center. Viewport projection never mutates saved coordinates.
class TablePosition {
  TablePosition(this.x, this.y) {
    if (!x.isFinite || !y.isFinite || x < 0 || x > 1 || y < 0 || y > 1) {
      throw ArgumentError('Position must be finite and within [0,1]');
    }
  }
  final double x, y;
  @override
  bool operator ==(Object other) =>
      other is TablePosition && x == other.x && y == other.y;
  @override
  int get hashCode => Object.hash(x, y);
}

class SpreadSlot {
  SpreadSlot({
    required this.slotId,
    required this.position,
    required this.meaningKey,
    this.requiredArcana,
  }) {
    requireText(slotId, 'slotId');
    requireText(meaningKey, 'meaningKey');
  }
  final String slotId, meaningKey;
  final ArcanaType? requiredArcana;
  final TablePosition position;
}

class SpreadDefinition {
  SpreadDefinition({
    required this.spreadId,
    required this.nameKey,
    required this.descriptionKey,
    required this.requiredCardCount,
    required Iterable<SpreadSlot> slots,
  }) : slots = List.unmodifiable(slots) {
    for (final value in [spreadId, nameKey, descriptionKey]) {
      requireText(value, 'spread');
    }
    if (spreadId == 'FREE' ||
        requiredCardCount < 1 ||
        requiredCardCount > 78 ||
        this.slots.length != requiredCardCount ||
        this.slots.map((s) => s.slotId).toSet().length != requiredCardCount) {
      throw ArgumentError('Invalid spread slots/count');
    }
  }
  final String spreadId, nameKey, descriptionKey;
  final int requiredCardCount;
  final List<SpreadSlot> slots;
}
