import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../free_reading/card_face.dart';
import 'library_screen.dart';

/// Full detail page for one card in the Card Library (M7): larger artwork,
/// keywords, concise/extended meaning, symbolism and (only if present in
/// the editorial corpus) element/astrology metadata. Never fabricates
/// content and never shows any reversed-card text.
///
/// Previous/Next walk [navigation]'s ordered id list (the search/filter
/// order the user arrived from), falling back to full deck order when
/// opened directly (e.g. a deep link). Buttons are disabled — not
/// wrapped — at the first/last card.
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId, this.navigation});
  final String cardId;
  final LibraryNavigationContext? navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckProvider);
    final card = deck.card(cardId);
    final content = ref.watch(
      editorialContentProvider,
    )[card.editorialContentId];

    final ids = navigation?.orderedIds ?? deck.cardIds;
    final index = navigation?.index ?? ids.indexOf(cardId);
    final hasPrevious = index > 0;
    final hasNext = index >= 0 && index < ids.length - 1;

    void goTo(int newIndex) {
      final targetId = ids[newIndex];
      context.pushReplacement(
        '/library/$targetId',
        extra: LibraryNavigationContext(orderedIds: ids, index: newIndex),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(card.canonicalName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CardFace(
                    width: 200,
                    artworkAssetId: card.artworkAssetId,
                    faceUp: true,
                    name: card.canonicalName,
                    number: card.numberOrRank,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    card.canonicalName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (content == null)
                    const Text(
                      'Conteúdo editorial em preparação para este baralho.',
                    )
                  else ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final k in content.keywords) Chip(label: Text(k)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        content.conciseMeaning,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(content.extendedMeaning),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Simbolismo',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(content.symbolism),
                    ),
                    if (content.element != null ||
                        content.astrology != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (content.element != null)
                            Text('Elemento: ${content.element}'),
                          if (content.astrology != null)
                            Text('Astrologia: ${content.astrology}'),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('library-detail-previous'),
                        onPressed: hasPrevious ? () => goTo(index - 1) : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Anterior'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        key: const Key('library-detail-next'),
                        onPressed: hasNext ? () => goTo(index + 1) : null,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Próxima'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
