import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/cards/editorial_content.dart';
import '../../domain/cards/tarot_card.dart';
import '../free_reading/card_face.dart';

/// Category filter for the Card Library grid. `all` shows every card;
/// the others mirror [ArcanaType.major] and each [Suit].
enum LibraryCategory { all, major, wands, cups, swords, pentacles }

extension LibraryCategoryLabel on LibraryCategory {
  String get label => switch (this) {
    LibraryCategory.all => 'Todas',
    LibraryCategory.major => 'Arcanos Maiores',
    LibraryCategory.wands => 'Paus',
    LibraryCategory.cups => 'Copas',
    LibraryCategory.swords => 'Espadas',
    LibraryCategory.pentacles => 'Ouros',
  };

  bool matches(TarotCard card) => switch (this) {
    LibraryCategory.all => true,
    LibraryCategory.major => card.arcanaType == ArcanaType.major,
    LibraryCategory.wands => card.suit == Suit.wands,
    LibraryCategory.cups => card.suit == Suit.cups,
    LibraryCategory.swords => card.suit == Suit.swords,
    LibraryCategory.pentacles => card.suit == Suit.pentacles,
  };
}

/// The ordered list of card ids the user was browsing (after search/filter)
/// plus the tapped index, carried through go_router `extra` so the detail
/// screen's Previous/Next buttons walk the same order the user arrived from.
class LibraryNavigationContext {
  const LibraryNavigationContext({
    required this.orderedIds,
    required this.index,
  });
  final List<String> orderedIds;
  final int index;
}

String normalizeForSearch(String input) {
  const withDiacritics = 'áàãâäéèêëíìîïóòõôöúùûüçñÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑ';
  const without = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final idx = withDiacritics.indexOf(ch);
    buffer.write(idx == -1 ? ch : without[idx]);
  }
  return buffer.toString().toLowerCase();
}

/// Complete searchable/browsable library of all 78 cards (M7). Search is
/// live, case/accent-insensitive, and matches canonical name or keywords.
/// Category chips filter by arcana/suit. No reversed-card UI of any kind.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  LibraryCategory _category = LibraryCategory.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TarotCard> _filter(
    List<TarotCard> cards,
    Map<String, EditorialContent> content,
  ) {
    final query = normalizeForSearch(_query.trim());
    return cards.where((card) {
      if (!_category.matches(card)) return false;
      if (query.isEmpty) return true;
      if (normalizeForSearch(card.canonicalName).contains(query)) return true;
      final keywords = content[card.editorialContentId]?.keywords ?? const [];
      return keywords.any((k) => normalizeForSearch(k).contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(deckProvider);
    final content = ref.watch(editorialContentProvider);
    final filtered = _filter(deck.cards, content);
    final orderedIds = filtered.map((c) => c.cardId).toList();

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca de cartas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '78 arcanos',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque em uma carta para ver seu significado completo.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('library-search'),
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nome ou palavra-chave',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in LibraryCategory.values)
                  ChoiceChip(
                    key: Key('library-category-${category.name}'),
                    label: Text(category.label),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Nenhuma carta encontrada.'))
                  : GridView.builder(
                      key: const Key('library-grid'),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 140,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final card = filtered[index];
                        return InkWell(
                          key: Key('library-card-${card.cardId}'),
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.push(
                            '/library/${card.cardId}',
                            extra: LibraryNavigationContext(
                              orderedIds: orderedIds,
                              index: index,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              children: [
                                Expanded(
                                  child: CardFace(
                                    width: 100,
                                    artworkAssetId: card.artworkAssetId,
                                    faceUp: true,
                                    name: card.canonicalName,
                                    number: card.numberOrRank,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  card.canonicalName,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
