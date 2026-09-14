enum ArcanaType { major, minor }

enum Suit { wands, cups, swords, pentacles }

void requireText(String value, String field) {
  if (value.trim().isEmpty) throw ArgumentError.value(value, field);
}

class TarotCard {
  TarotCard({
    required this.cardId,
    required this.canonicalName,
    required this.arcanaType,
    required this.numberOrRank,
    this.suit,
    required this.artworkAssetId,
    required this.editorialContentId,
    Map<String, String> metadata = const {},
  }) : metadata = Map.unmodifiable(metadata) {
    for (final value in [
      cardId,
      canonicalName,
      artworkAssetId,
      editorialContentId,
    ]) {
      requireText(value, 'card identity');
    }
    if (arcanaType == ArcanaType.major
        ? suit != null || numberOrRank < 0 || numberOrRank > 21
        : suit == null || numberOrRank < 1 || numberOrRank > 14) {
      throw ArgumentError('Invalid arcana, suit or rank');
    }
  }
  final String cardId, canonicalName, artworkAssetId, editorialContentId;
  final ArcanaType arcanaType;
  final int numberOrRank;
  final Suit? suit;
  final Map<String, String> metadata;
}
