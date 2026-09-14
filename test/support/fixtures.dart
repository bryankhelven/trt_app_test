import 'package:tarot_app/domain/cards/editorial_content.dart';
import 'package:tarot_app/domain/cards/tarot_card.dart';
import 'package:tarot_app/domain/decks/tarot_deck.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';

final epoch = DateTime.utc(2026, 9, 5);
TarotDeck fixtureDeck() => TarotDeck(
  deckId: 'fixture',
  title: 'Fixture only',
  version: 'dev-1',
  source: 'Generated test identities',
  provenanceManifest: 'fixture',
  contentProfile: 'pending',
  schemaVersion: 1,
  cards: List.generate(
    78,
    (i) => TarotCard(
      cardId: 'card-$i',
      canonicalName: 'Fixture $i',
      arcanaType: i < 22 ? ArcanaType.major : ArcanaType.minor,
      numberOrRank: i < 22 ? i : (i - 22) % 14 + 1,
      suit: i < 22 ? null : Suit.values[(i - 22) ~/ 14],
      artworkAssetId: 'placeholder',
      editorialContentId: 'pending-$i',
    ),
  ),
);
ReadingSession fixtureSession() => ReadingSession.start(
  readingId: 'reading-1',
  deck: fixtureDeck(),
  drawOrder: fixtureDeck().cardIds,
  now: epoch,
);

/// Fixture PT-BR-shaped editorial content for the 78 [fixtureDeck] cards,
/// keyed by `editorialContentId` (`pending-0`..`pending-77`) as
/// [TarotDeck.card] links them. Card `card-30` carries a unique
/// `chave-especial` keyword for keyword-search tests; even-indexed cards
/// have an `element`, and every third has an `astrology`, so both the
/// "present" and "cleanly omitted" metadata paths are exercised.
Map<String, EditorialContent> fixtureEditorialContent() => {
  for (var i = 0; i < 78; i++)
    'pending-$i': EditorialContent(
      cardId: 'card-$i',
      keywords: ['tema-$i', if (i == 30) 'chave-especial'],
      conciseMeaning: 'Significado conciso $i',
      extendedMeaning: 'Significado estendido $i',
      symbolism: 'Simbolismo $i',
      element: i.isEven ? 'Fogo' : null,
      astrology: i % 3 == 0 ? 'Marte' : null,
    ),
};
