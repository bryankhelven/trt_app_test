import '../../domain/cards/tarot_card.dart';
import '../../domain/decks/tarot_deck.dart';

/// Development identities only. No final artwork or Hermetic editorial authority.
TarotDeck developmentDeck() => TarotDeck(
  deckId: 'development',
  title: 'Baralho provisório',
  version: 'dev-1',
  source: 'Generated development placeholders',
  provenanceManifest: 'docs/DEVELOPMENT_ASSETS.md',
  contentProfile: 'editorial-pending-dev-1',
  schemaVersion: 1,
  cards: List.generate(
    78,
    (i) => TarotCard(
      cardId: 'dev-$i',
      canonicalName: i < 22 ? 'Arcano maior $i' : 'Carta menor ${i - 21}',
      arcanaType: i < 22 ? ArcanaType.major : ArcanaType.minor,
      numberOrRank: i < 22 ? i : (i - 22) % 14 + 1,
      suit: i < 22 ? null : Suit.values[(i - 22) ~/ 14],
      artworkAssetId: 'development-card-renderer',
      editorialContentId: 'pending-$i',
      metadata: const {'status': 'development-placeholder'},
    ),
  ),
);
