import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/cards/tarot_card.dart';
import '../../domain/decks/tarot_deck.dart';
import 'card_face.dart';

class DeckChoice {
  const DeckChoice({this.cardId, this.reordered});
  final String? cardId;
  final List<String>? reordered;
}

/// Display/filter never changes the source pile or reveals a card identity.
class DeckPicker extends StatefulWidget {
  const DeckPicker({
    super.key,
    required this.ids,
    required this.deck,
    this.requiredArcana,
    this.initialMode = 0,
  });
  final List<String> ids;
  final TarotDeck deck;
  final ArcanaType? requiredArcana;
  final int initialMode;
  @override
  State<DeckPicker> createState() => _DeckPickerState();
}

class _DeckPickerState extends State<DeckPicker> {
  late int mode = widget.initialMode;
  late ArcanaType? filter = widget.requiredArcana;
  int cursor = 0, pile = 0, count = 2;
  late int cut1 = math.max(1, widget.ids.length ~/ 2);
  late int cut2 = math.max(2, widget.ids.length * 2 ~/ 3);
  List<List<String>> get piles {
    final first = cut1.clamp(1, math.max(1, widget.ids.length - 1)).toInt();
    final second = cut2
        .clamp(first + 1, math.max(first + 1, widget.ids.length - 1))
        .toInt();
    return count == 2
        ? [widget.ids.take(first).toList(), widget.ids.skip(first).toList()]
        : [
            widget.ids.take(first).toList(),
            widget.ids.sublist(first, second),
            widget.ids.skip(second).toList(),
          ];
  }

  List<String> get visible => (mode == 2 ? piles[pile] : widget.ids)
      .where(
        (id) => filter == null || widget.deck.card(id).arcanaType == filter,
      )
      .toList();
  void choose(String id) => Navigator.pop(context, DeckChoice(cardId: id));
  Widget card(String id, double width) => Semantics(
    label: 'Escolher carta fechada ${widget.ids.indexOf(id) + 1}',
    button: true,
    child: InkWell(
      key: Key('choose-${widget.ids.indexOf(id)}'),
      onTap: () => choose(id),
      child: ExcludeSemantics(child: CardFace(width: width)),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final ids = visible;
    cursor = cursor.clamp(0, math.max(0, ids.length - 1));
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: _PickerViewport(
          minHeight: mode == 2 ? 860 : 620,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Escolha com calma',
                        style: TextStyle(
                          fontFamily: 'ArcanumSerif',
                          fontSize: 26,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cancelar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                  'Escolha fechada. A carta só será retirada quando você a colocar na mesa.',
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Distribuídas')),
                      ButtonSegment(value: 1, label: Text('Percorrer')),
                      ButtonSegment(value: 2, label: Text('Dividir')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (v) => setState(() {
                      mode = v.first;
                      cursor = 0;
                      pile = 0;
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Baralho inteiro')),
                      ButtonSegment(value: 1, label: Text('Maiores')),
                      ButtonSegment(value: 2, label: Text('Menores')),
                    ],
                    selected: {
                      filter == null
                          ? 0
                          : filter == ArcanaType.major
                          ? 1
                          : 2,
                    },
                    onSelectionChanged: widget.requiredArcana != null
                        ? null
                        : (v) => setState(() {
                            filter = v.first == 0
                                ? null
                                : ArcanaType.values[v.first - 1];
                            cursor = 0;
                          }),
                  ),
                ),
                if (widget.requiredArcana != null)
                  Text(
                    'Esta posição pede um arcano ${widget.requiredArcana == ArcanaType.major ? 'maior' : 'menor'}.',
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          if (mode == 2) ...[
                            if (widget.ids.length >= 3)
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('Montes: '),
                                  ChoiceChip(
                                    label: const Text('2'),
                                    selected: count == 2,
                                    onSelected: (_) => setState(() {
                                      count = 2;
                                      pile = 0;
                                      cut1 = widget.ids.length ~/ 2;
                                    }),
                                  ),
                                  ChoiceChip(
                                    label: const Text('3'),
                                    selected: count == 3,
                                    onSelected: (_) => setState(() {
                                      count = 3;
                                      pile = 0;
                                      cut1 = widget.ids.length ~/ 3;
                                      cut2 = widget.ids.length * 2 ~/ 3;
                                    }),
                                  ),
                                ],
                              ),
                            if (widget.ids.length > count)
                              Row(
                                children: [
                                  Text('Corte 1: $cut1'),
                                  Expanded(
                                    child: Slider(
                                      key: const Key('cut-first'),
                                      min: 1,
                                      max:
                                          (count == 3
                                                  ? cut2 - 1
                                                  : widget.ids.length - 1)
                                              .toDouble(),
                                      value: cut1.toDouble(),
                                      divisions: math.max(
                                        1,
                                        (count == 3
                                                ? cut2 - 1
                                                : widget.ids.length - 1) -
                                            1,
                                      ),
                                      onChanged: (v) =>
                                          setState(() => cut1 = v.round()),
                                    ),
                                  ),
                                ],
                              ),
                            if (count == 3 && widget.ids.length > 3)
                              Row(
                                children: [
                                  Text('Corte 2: $cut2'),
                                  Expanded(
                                    child: Slider(
                                      min: (cut1 + 1).toDouble(),
                                      max: (widget.ids.length - 1).toDouble(),
                                      value: cut2.toDouble(),
                                      onChanged: (v) =>
                                          setState(() => cut2 = v.round()),
                                    ),
                                  ),
                                ],
                              ),
                            Wrap(
                              spacing: 6,
                              children: [
                                for (var i = 0; i < count; i++)
                                  ChoiceChip(
                                    label: Text(
                                      'Monte ${i + 1} · ${piles[i].length}',
                                    ),
                                    selected: pile == i,
                                    onSelected: (_) => setState(() {
                                      pile = i;
                                      cursor = 0;
                                    }),
                                  ),
                              ],
                            ),
                          ],
                          Expanded(
                            child: ids.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Não há cartas desse grupo neste monte.',
                                    ),
                                  )
                                : mode == 1
                                ? Column(
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: card(ids[cursor], 120),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            tooltip: 'Carta anterior',
                                            onPressed: cursor > 0
                                                ? () => setState(() => cursor--)
                                                : null,
                                            icon: const Icon(
                                              Icons.chevron_left,
                                            ),
                                          ),
                                          Text(
                                            '${cursor + 1} de ${ids.length}',
                                          ),
                                          IconButton(
                                            tooltip: 'Próxima carta',
                                            onPressed: cursor < ids.length - 1
                                                ? () => setState(() => cursor++)
                                                : null,
                                            icon: const Icon(
                                              Icons.chevron_right,
                                            ),
                                          ),
                                        ],
                                      ),
                                      FilledButton(
                                        onPressed: () => choose(ids[cursor]),
                                        child: const Text(
                                          'Escolher esta carta',
                                        ),
                                      ),
                                    ],
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 82,
                                          childAspectRatio: .6,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                        ),
                                    itemCount: ids.length,
                                    itemBuilder: (_, i) => card(ids[i], 66),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (mode == 2)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      DeckChoice(
                        reordered: [
                          for (var i = 0; i < count; i++)
                            ...piles[(pile + i) % count],
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.layers),
                    label: const Text('Reunir a partir deste monte'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerViewport extends StatelessWidget {
  const _PickerViewport({required this.child, required this.minHeight});
  final double minHeight;
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      child: SizedBox(
        height: math.max(
          minHeight * (MediaQuery.textScalerOf(context).scale(12) / 12),
          c.maxHeight,
        ),
        child: child,
      ),
    ),
  );
}
