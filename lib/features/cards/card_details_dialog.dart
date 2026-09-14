import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/cards/tarot_card.dart';
import '../free_reading/card_face.dart';
import '../free_reading/position_insight.dart';

/// "Sobre a carta": shared card-detail overlay used by Free Reading, the
/// predefined spreads and the Card Library. Shows the real bundled artwork
/// and original PT-BR editorial corpus when available, and a clearly
/// labelled provisional notice for decks that don't have content yet (e.g.
/// the development placeholder deck used in tests).
class CardDetailsDialog extends ConsumerWidget {
  const CardDetailsDialog({
    super.key,
    required this.card,
    this.positionMeaning,
  });
  final TarotCard card;
  final String? positionMeaning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(
      editorialContentProvider,
    )[card.editorialContentId];
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sobre a carta',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar informações',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardFace(
                        width: 96,
                        artworkAssetId: card.artworkAssetId,
                        faceUp: true,
                        name: card.canonicalName,
                        number: card.numberOrRank,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (positionMeaning != null) ...[
                              Text(
                                positionMeaning!,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                positionPrompt(positionMeaning!),
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              card.canonicalName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            if (content == null) ...[
                              const Text(
                                'Conteúdo editorial em preparação para este baralho.',
                              ),
                            ] else ...[
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final k in content.keywords)
                                    Chip(
                                      label: Text(k),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                content.conciseMeaning,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(content.extendedMeaning),
                              const SizedBox(height: 12),
                              Text(
                                'Simbolismo',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(content.symbolism),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
