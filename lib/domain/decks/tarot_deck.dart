import '../cards/tarot_card.dart';

class TarotDeck {
  TarotDeck({
    required this.deckId,
    required this.title,
    required this.version,
    required this.source,
    required this.provenanceManifest,
    required this.contentProfile,
    required this.schemaVersion,
    required Iterable<TarotCard> cards,
  }) : cards = List.unmodifiable(cards) {
    for (final value in [
      deckId,
      title,
      version,
      source,
      provenanceManifest,
      contentProfile,
    ]) {
      requireText(value, 'deck metadata');
    }
    if (schemaVersion != 1 ||
        this.cards.length != 78 ||
        cardIds.toSet().length != 78) {
      throw ArgumentError('Deck requires schema 1 and 78 unique cards');
    }
  }
  final String deckId,
      title,
      version,
      source,
      provenanceManifest,
      contentProfile;
  final int schemaVersion;
  final List<TarotCard> cards;
  List<String> get cardIds => List.unmodifiable(cards.map((c) => c.cardId));
  TarotCard card(String id) => cards.firstWhere((c) => c.cardId == id);
}
