import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/cards/editorial_content.dart';
import '../../domain/cards/tarot_card.dart';
import '../../domain/decks/tarot_deck.dart';

const rwsDeckId = 'rws_v1';
const _manifestPath = 'assets/decks/rws_v1/deck_manifest.json';
const _contentPath = 'assets/decks/rws_v1/content/editorial_pt_br.json';
const _provenancePath = 'assets/decks/rws_v1/PROVENANCE.json';

ArcanaType _arcana(String s) =>
    s == 'major' ? ArcanaType.major : ArcanaType.minor;
Suit? _suit(String? s) => switch (s) {
  'wands' => Suit.wands,
  'cups' => Suit.cups,
  'swords' => Suit.swords,
  'pentacles' => Suit.pentacles,
  _ => null,
};

/// Loads the bundled Rider-Waite-Smith (1909, public domain) deck manifest
/// into the domain [TarotDeck]. Card artwork/provenance references point at
/// `assets/decks/rws_v1/artwork/`; see docs/licenses/RWS_DECK_LICENSE.md and
/// PROVENANCE.json for per-asset sourcing.
Future<TarotDeck> loadRwsDeck() async {
  final manifest = jsonDecode(
    await rootBundle.loadString(_manifestPath),
  ) as Map<String, dynamic>;
  final cards = (manifest['cards'] as List).map((raw) {
    final c = raw as Map<String, dynamic>;
    return TarotCard(
      cardId: c['cardId'] as String,
      canonicalName: c['canonicalName'] as String,
      arcanaType: _arcana(c['arcanaType'] as String),
      numberOrRank: c['numberOrRank'] as int,
      suit: _suit(c['suit'] as String?),
      artworkAssetId: c['artworkAssetId'] as String,
      editorialContentId: c['editorialContentId'] as String,
    );
  });
  return TarotDeck(
    deckId: manifest['deckId'] as String,
    title: manifest['title'] as String,
    version: manifest['version'] as String,
    source: manifest['source'] as String,
    provenanceManifest: _provenancePath,
    contentProfile: 'rws_v1-pt_br-1',
    schemaVersion: manifest['schemaVersion'] as int,
    cards: cards,
  );
}

/// Loads the original PT-BR editorial corpus, keyed by
/// [TarotCard.editorialContentId].
Future<Map<String, EditorialContent>> loadEditorialContent() async {
  final data = jsonDecode(
    await rootBundle.loadString(_contentPath),
  ) as Map<String, dynamic>;
  final result = <String, EditorialContent>{};
  for (final raw in data['cards'] as List) {
    final c = raw as Map<String, dynamic>;
    result[c['card_id'] as String] = EditorialContent(
      cardId: c['card_id'] as String,
      keywords: (c['keywords'] as List).cast<String>(),
      conciseMeaning: c['concise_meaning'] as String,
      extendedMeaning: c['extended_meaning'] as String,
      symbolism: c['symbolism'] as String,
      element: c['hermeticApproved'] == true ? c['element'] as String? : null,
      astrology: c['hermeticApproved'] == true
          ? c['astrology'] as String?
          : null,
    );
  }
  return result;
}
