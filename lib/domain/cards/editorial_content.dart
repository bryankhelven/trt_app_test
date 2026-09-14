import 'tarot_card.dart';

/// Original v1 editorial corpus for a card. School-specific disputed
/// correspondences (Hebrew letter, Tree-of-Life path, decan) are
/// intentionally absent from this schema: see docs/spec/06 and
/// docs/spec/11_OPEN_DECISIONS.md.
class EditorialContent {
  EditorialContent({
    required this.cardId,
    required this.keywords,
    required this.conciseMeaning,
    required this.extendedMeaning,
    required this.symbolism,
    this.element,
    this.astrology,
  }) {
    requireText(cardId, 'cardId');
    requireText(conciseMeaning, 'conciseMeaning');
    requireText(extendedMeaning, 'extendedMeaning');
    requireText(symbolism, 'symbolism');
    if (keywords.isEmpty) {
      throw ArgumentError('keywords must not be empty');
    }
  }
  final String cardId, conciseMeaning, extendedMeaning, symbolism;
  final List<String> keywords;
  final String? element, astrology;
}
