import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/domain/cards/tarot_card.dart';
import 'package:tarot_app/infrastructure/assets/rws_deck.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Bundled RWS deck manifest has 78 unique, correctly-typed cards',
    () async {
      final deck = await loadRwsDeck();
      expect(deck.deckId, 'rws_v1');
      expect(deck.cards.length, 78);
      expect(deck.cardIds.toSet().length, 78);
      final majors = deck.cards.where((c) => c.arcanaType == ArcanaType.major);
      expect(majors.length, 22);
      for (final suit in Suit.values) {
        expect(deck.cards.where((c) => c.suit == suit).length, 14);
      }
      for (final c in deck.cards) {
        expect(c.artworkAssetId, startsWith('assets/decks/rws_v1/artwork/'));
        expect(c.editorialContentId, isNotEmpty);
      }
    },
  );

  test('Bundled PT-BR editorial corpus covers every deck card with non-empty required fields', () async {
    final deck = await loadRwsDeck();
    final content = await loadEditorialContent();
    expect(content.length, 78);
    for (final card in deck.cards) {
      final entry = content[card.editorialContentId];
      expect(entry, isNotNull, reason: 'missing content for ${card.cardId}');
      expect(entry!.keywords, isNotEmpty);
      expect(entry.conciseMeaning, isNotEmpty);
      expect(entry.extendedMeaning, isNotEmpty);
      expect(entry.symbolism, isNotEmpty);
    }
  });
}
