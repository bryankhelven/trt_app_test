import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/reading_table_background.dart';
import '../../domain/readings/reading_session.dart';
import '../../domain/spreads/spread_catalog.dart';
import '../../domain/spreads/spread_definition.dart';
import '../cards/card_details_dialog.dart';
import '../settings/banner_ad_slot.dart';
import 'card_face.dart';
import 'card_motion.dart';
import '../settings/settings_controller.dart';
import 'reading_controller.dart';
import 'deck_picker.dart';
import 'table_geometry.dart';
import 'position_insight.dart';

class FreeReadingScreen extends ConsumerStatefulWidget {
  const FreeReadingScreen({super.key, this.modeId = 'FREE'});
  final String modeId;
  @override
  ConsumerState<FreeReadingScreen> createState() => _FreeReadingScreenState();
}

class _Drag {
  _Drag(this.id, this.point);
  final String? id;
  Offset point;
}

class _FreeReadingScreenState extends ConsumerState<FreeReadingScreen> {
  final _tableKey = GlobalKey();
  final _transform = TransformationController();
  final _tooltipKeys = <String, GlobalKey<TooltipState>>{};
  _Drag? _drag;
  String? _selectedId;
  final _releaseOrigins = <String, Offset>{};
  TableGeometry? _geometry;
  ReadingControllerProvider get _provider =>
      readingControllerProviderFor(widget.modeId);
  ReadingController get _controller => ref.read(_provider.notifier);
  late ProviderContainer _container;
  @override
  void initState() {
    super.initState();
    ref.invalidate(_provider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void didUpdateWidget(covariant FreeReadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modeId != widget.modeId) {
      ref.invalidate(readingControllerProviderFor(oldWidget.modeId));
      ref.invalidate(_provider);
      _selectedId = null;
      _releaseOrigins.clear();
      _drag = null;
      _transform.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    // Dispose only memory. Persisted snapshots are never removed by navigation.
    _container.invalidate(_provider);
    _transform.dispose();
    super.dispose();
  }

  Offset _local(Offset point) =>
      (_tableKey.currentContext!.findRenderObject()! as RenderBox)
          .globalToLocal(point);
  Future<void> _choose(
    ReadingSession session, {
    SpreadSlot? target,
    int initialMode = 0,
  }) async {
    if (session.remaining == 0) return;
    final result = await showDialog<DeckChoice>(
      context: context,
      builder: (_) => DeckPicker(
        ids: session.drawOrder.skip(session.placed.length).toList(),
        deck: ref.read(deckProvider),
        requiredArcana: target?.requiredArcana,
        initialMode: initialMode,
      ),
    );
    if (!mounted || result == null) return;
    if (result.reordered != null) {
      await _controller.reorderRemaining(result.reordered!);
      setState(() => _selectedId = null);
      _announce('Montes reunidos na ordem escolhida.');
      return;
    }
    if (target != null && result.cardId != null) {
      final index = session.drawOrder
          .skip(session.placed.length)
          .toList()
          .indexOf(result.cardId!);
      await _draw(target.position, index: index, slotId: target.slotId);
    } else {
      setState(() => _selectedId = result.cardId);
    }
  }

  Future<void> _draw(
    TablePosition p, {
    required int index,
    String? slotId,
    String? complementOf,
  }) async {
    try {
      await _controller.draw(
        p,
        index: index,
        slotId: slotId,
        complementOf: complementOf,
      );
      if (mounted) setState(() => _selectedId = null);
    } on StateError catch (e) {
      _announce(e.message.toString());
    }
  }

  void _place(
    Offset point,
    TableGeometry g,
    ReadingSession s, {
    String? moving,
  }) {
    final rect = Rect.fromCenter(
      center: point,
      width: g.width,
      height: g.width * 5 / 3,
    );
    if (!(Offset.zero & g.size).contains(rect.topLeft) ||
        !(Offset.zero & g.size).contains(rect.bottomRight) ||
        rect.overlaps(g.deck.inflate(6))) {
      return;
    }
    final slots = s.spread?.slots ?? <SpreadSlot>[];
    // Topmost crossing slot wins, matching the visible geometry.
    final target = slots.reversed
        .where((slot) => g.cards[slot.slotId]!.contains(point))
        .firstOrNull;
    final occupied =
        target != null &&
        s.placed.any((c) => c.slotId == target.slotId && c.cardId != moving);
    String? complementOf;
    if (occupied) {
      complementOf = ReadingSession.positionId(target.slotId);
    } else if (target == null && !g.staging.contains(point)) {
      final existing = s.placed.reversed
          .where(
            (c) =>
                c.cardId != moving &&
                c.complementOf != null &&
                g.cardRect(c, s).contains(point),
          )
          .firstOrNull;
      final occupiedPositions = s.placed
          .where((card) => card.slotId != null && card.cardId != moving)
          .map((card) => ReadingSession.positionId(card.slotId!))
          .toSet();
      complementOf =
          existing?.complementOf ??
          g.complements.entries
              .where(
                (entry) =>
                    occupiedPositions.contains(entry.key) &&
                    entry.value.inflate(g.width * .35).contains(point),
              )
              .firstOrNull
              ?.key;
    }
    final slotId = occupied ? null : target?.slotId;
    final position = TablePosition(
      point.dx / g.size.width,
      point.dy / g.size.height,
    );
    if (moving != null) {
      _releaseOrigins[moving] = point;
      _controller
          .move(moving, position, slotId: slotId, complementOf: complementOf)
          .catchError((Object e) {
            if (e is StateError) _announce(e.message.toString());
          });
      return;
    }
    final rest = s.drawOrder.skip(s.placed.length).toList();
    if (rest.isEmpty) return;
    final index = _selectedId == null ? 0 : rest.indexOf(_selectedId!);
    if (index < 0) return;
    _releaseOrigins[rest[index]] = point;
    _draw(position, index: index, slotId: slotId, complementOf: complementOf);
  }

  Widget _gesture({
    String? id,
    required Widget child,
    required ReadingSession session,
    required TableGeometry geometry,
    required VoidCallback onTap,
  }) => Listener(
    onPointerCancel: (_) {
      if (_drag != null) setState(() => _drag = null);
    },
    child: FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.start,
        onTap: onTap,
        onPanStart: (d) {
          if (id == null && session.remaining == 0) return;
          setState(() => _drag = _Drag(id, _local(d.globalPosition)));
        },
        onPanUpdate: (d) {
          if (_drag != null) {
            setState(() => _drag!.point = _local(d.globalPosition));
          }
        },
        onPanCancel: () => setState(() => _drag = null),
        onPanEnd: (_) {
          final drag = _drag;
          setState(() => _drag = null);
          if (drag != null) {
            _place(drag.point, geometry, session, moving: drag.id);
          }
        },
        child: child,
      ),
    ),
  );
  String _meaning(ReadingSession s, PlacedCard c) => s.cardLabel(c);
  Widget _insight(
    String meaning,
    ReadingSession s, {
    PlacedCard? placed,
    required Widget child,
  }) {
    final card = placed?.revealed == true
        ? ref.read(deckProvider).card(placed!.cardId)
        : null;
    final content = card == null
        ? null
        : ref.read(editorialContentProvider)[card.editorialContentId];
    final tooltipKey = _tooltipKeys.putIfAbsent(
      '${placed?.cardId ?? meaning}:${child.runtimeType}',
      () => GlobalKey<TooltipState>(),
    );
    return Focus(
      canRequestFocus: false,
      onFocusChange: (focused) {
        if (focused) tooltipKey.currentState?.ensureTooltipVisible();
      },
      child: Tooltip(
        key: tooltipKey,
        ignorePointer: true,
        waitDuration: const Duration(milliseconds: 200),
        showDuration: const Duration(seconds: 15),
        preferBelow: false,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xEE211A31),
          border: Border.all(color: const Color(0x887F7290)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20)],
        ),
        richMessage: WidgetSpan(
          child: PositionInsight(
            meaning: meaning,
            card: card,
            content: content,
          ),
        ),
        child: child,
      ),
    );
  }

  void _cardTap(ReadingSession s, PlacedCard c) {
    if (!c.revealed) {
      _controller.reveal(c.cardId);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => CardDetailsDialog(
        card: ref.read(deckProvider).card(c.cardId),
        positionMeaning: _meaning(s, c),
      ),
    );
  }

  Future<void> _notes(ReadingSession s) async {
    final question = TextEditingController(text: s.question),
        notes = TextEditingController(text: s.notes);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sua leitura'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: question,
                decoration: const InputDecoration(
                  labelText: 'Pergunta (opcional)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notes,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Notas pessoais'),
              ),
              const SizedBox(height: 16),
              const Text(
                'As notas só entram no diário ao tocar em Salvar tiragem.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aplicar notas'),
          ),
        ],
      ),
    );
    if (save == true && mounted) {
      await _controller.annotate(question.text, notes.text);
    }
    // Controllers outlive the dialog exit animation.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    question.dispose();
    notes.dispose();
  }

  void _announce(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _newReading() async {
    final view = ref.read(_provider).requireValue;
    if (!view.saved &&
        (view.session.placed.isNotEmpty ||
            view.session.notes.isNotEmpty ||
            view.session.question.isNotEmpty)) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nova tiragem?'),
          content: const Text(
            'As alterações não salvas serão descartadas. Use Salvar tiragem antes se quiser guardá-las.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuar esta'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Descartar e começar'),
            ),
          ],
        ),
      );
      if (!mounted || yes != true) return;
    }
    setState(() {
      _drag = null;
      _selectedId = null;
      _transform.value = Matrix4.identity();
    });
    await _controller.newReading();
  }

  void _positions(ReadingSession s) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Posições da tiragem'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final slot in s.spread?.slots ?? <SpreadSlot>[])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '${slot.meaningKey}\n${positionPrompt(slot.meaningKey)}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(_provider);
    final viewport = MediaQuery.sizeOf(context);
    final landscape = viewport.height < 500 && viewport.width > viewport.height;
    return Scaffold(
      appBar: landscape
          ? null
          : AppBar(
              leading: IconButton(
                tooltip: 'Início',
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text(
                SpreadCatalog.byId(widget.modeId).name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'ArcanumSerif',
                  fontSize: 23,
                ),
              ),
              actions: [
                if (reading.hasValue)
                  IconButton(
                    tooltip: 'Notas da leitura',
                    onPressed: () => _notes(reading.requireValue.session),
                    icon: const Icon(Icons.edit_note),
                  ),
              ],
            ),
      body: SafeArea(
        child: reading.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(_provider),
              child: const Text('Tentar novamente'),
            ),
          ),
          data: (view) => Column(
            children: [
              // Controls scroll horizontally on narrow screens; the board keeps its space.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (landscape) ...[
                      IconButton(
                        tooltip: 'Início',
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Text(
                        SpreadCatalog.byId(widget.modeId).name,
                        style: const TextStyle(
                          fontFamily: 'ArcanumSerif',
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Notas da leitura',
                        onPressed: () => _notes(view.session),
                        icon: const Icon(Icons.edit_note),
                      ),
                    ],
                    TextButton.icon(
                      key: const Key('new-reading'),
                      onPressed: view.saving ? null : _newReading,
                      icon: const Icon(Icons.add),
                      label: const Text('Nova tiragem'),
                    ),
                    FilledButton.icon(
                      key: const Key('save-reading'),
                      onPressed: view.saving
                          ? null
                          : _controller.saveExplicitly,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: Text(view.saving ? 'Salvando…' : 'Salvar tiragem'),
                    ),
                    IconButton(
                      tooltip: 'Desfazer',
                      onPressed: _controller.canUndo
                          ? () {
                              setState(() => _selectedId = null);
                              _controller.undo();
                            }
                          : null,
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton(
                      tooltip: 'Refazer',
                      onPressed: _controller.canRedo
                          ? () {
                              setState(() => _selectedId = null);
                              _controller.redo();
                            }
                          : null,
                      icon: const Icon(Icons.redo),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Opções da mesa',
                      onSelected: (action) async {
                        setState(() => _selectedId = null);
                        switch (action) {
                          case 'shuffle':
                            await _controller.shuffleRemaining();
                            _announce('Baralho restante embaralhado.');
                          case 'cut':
                            await _controller.cutRemaining();
                            _announce('Baralho restante cortado ao meio.');
                          case 'split':
                            await _choose(view.session, initialMode: 2);
                          case 'pairs':
                            await _controller.setPaired(
                              !(view
                                      .session
                                      .spread
                                      ?.slots
                                      .first
                                      .requiredArcana !=
                                  null),
                            );
                          case 'positions':
                            _positions(view.session);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'shuffle',
                          enabled: view.session.remaining > 1,
                          child: const Text('Embaralhar restantes'),
                        ),
                        PopupMenuItem(
                          value: 'cut',
                          enabled: view.session.remaining > 1,
                          child: const Text('Cortar ao meio'),
                        ),
                        PopupMenuItem(
                          value: 'split',
                          enabled: view.session.remaining > 1,
                          child: const Text('Dividir baralho'),
                        ),
                        if (view.session.spread != null) ...[
                          PopupMenuItem(
                            value: 'pairs',
                            enabled: view.session.placed.isEmpty,
                            child: Text(
                              view.session.spread!.slots.first.requiredArcana !=
                                      null
                                  ? 'Usar uma carta por posição'
                                  : 'Usar maior + menor por posição',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'positions',
                            child: Text('Explicar posições'),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      tooltip: 'Ampliar mesa',
                      onPressed: () => setState(() {
                        _transform.value = Matrix4.identity()
                          ..scaleByDouble(1.8, 1.8, 1, 1);
                      }),
                      icon: const Icon(Icons.zoom_in),
                    ),
                    IconButton(
                      tooltip: 'Ajustar à tela',
                      onPressed: () =>
                          setState(() => _transform.value = Matrix4.identity()),
                      icon: const Icon(Icons.fit_screen),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        view.saved
                            ? 'Tiragem salva neste dispositivo'
                            : view.saveFailed
                            ? 'Falha ao salvar. A tiragem continua aberta.'
                            : 'Temporária · ao sair, o que não foi salvo é descartado.',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    if (view.saveFailed)
                      TextButton(
                        onPressed: _controller.retry,
                        child: const Text('Tentar salvar'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    return InteractiveViewer(
                      transformationController: _transform,
                      minScale: 1,
                      maxScale: 3,
                      panEnabled: _transform.value.getMaxScaleOnAxis() > 1.01,
                      onInteractionUpdate: (_) {
                        if (mounted) setState(() {});
                      },
                      child: SizedBox(
                        width: size.width,
                        height: size.height,
                        child: _buildTable(view.session, size),
                      ),
                    );
                  },
                ),
              ),
              const BannerAdSlot(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable(ReadingSession s, Size size) {
    if (_geometry?.size != size || !identical(_geometry?.spread, s.spread)) {
      _geometry = TableGeometry(size, s.spread);
    }
    final g = _geometry!;
    final reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        (ref.watch(settingsControllerProvider).value?.reducedMotion ?? false);
    final deck = ref.watch(deckProvider);
    final slots = s.spread?.slots ?? <SpreadSlot>[];
    final paired = slots.any((slot) => slot.requiredArcana != null);
    final coreCount = s.placed.where((card) => card.slotId != null).length;
    final progress = paired
        ? '$coreCount/${slots.length} cartas · ${slots.length ~/ 2} posições · maior + menor'
        : '$coreCount/${slots.length} posições principais';
    Widget face(String? id, {Key? key, double? width, bool animate = false}) {
      final placed = id == null
          ? null
          : s.placed.firstWhere((c) => c.cardId == id);
      final card = id == null ? null : deck.card(id);
      final front = CardFace(
        width: width ?? g.width,
        name: placed?.revealed == true ? card!.canonicalName : null,
        number: card?.numberOrRank,
        artworkAssetId: card?.artworkAssetId,
        faceUp: placed?.revealed ?? false,
      );
      if (!animate) return KeyedSubtree(key: key, child: front);
      return CardTurn(
        key: key,
        revealed: placed?.revealed ?? false,
        reducedMotion: reducedMotion,
        front: front,
        back: CardFace(width: width ?? g.width),
      );
    }

    final cards = [...s.placed]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return SizedBox(
      key: _tableKey,
      child: Stack(
        key: const Key('table'),
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(child: ReadingTableBackground()),
          Positioned.fill(
            child: CustomPaint(
              key: const Key('spread-lines'),
              painter: SpreadLines(g),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                if (_selectedId != null) _place(d.localPosition, g, s);
              },
            ),
          ),
          if (slots.isNotEmpty)
            Positioned(
              top: 12,
              left: 16,
              right: g.deck.width + 40,
              child: Text(
                '$progress${size.height < 450 ? '' : '\nEscolha, arraste e organize. As posições são livres para mover.'}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          if (slots.isNotEmpty)
            Positioned.fromRect(
              rect: g.staging,
              child: IgnorePointer(
                child: Container(
                  key: const Key('staging-area'),
                  decoration: BoxDecoration(
                    color: const Color(0x183C284F),
                    border: Border(
                      top: BorderSide(color: const Color(0x447F7290)),
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(6),
                  child: const Text(
                    'Área livre · retire aqui e arraste para uma posição',
                    style: TextStyle(fontSize: 10, color: Color(0xBBE4D7BC)),
                  ),
                ),
              ),
            ),
          for (var i = 0; i < slots.length; i++) ...[
            Positioned.fromRect(
              rect: g.cards[slots[i].slotId]!,
              child: _insight(
                slots[i].meaningKey,
                s,
                child: Semantics(
                  label: 'Posição ${slots[i].meaningKey}',
                  button: true,
                  child: InkWell(
                    key: Key('slot-${slots[i].slotId}'),
                    onTap: () {
                      if (_selectedId == null) {
                        _choose(s, target: slots[i]);
                      } else {
                        final rest = s.drawOrder.skip(s.placed.length).toList();
                        _draw(
                          slots[i].position,
                          index: rest.indexOf(_selectedId!),
                          slotId: slots[i].slotId,
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0x997F7290)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: math.max(9, g.width * .22),
                          color: const Color(0xBBD4BD87),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (cards.isEmpty && slots.isEmpty)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 290,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gesture,
                              size: 36,
                              color: Color(0xFFCAB78A),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'A mesa é sua.',
                              style: TextStyle(
                                fontFamily: 'ArcanumSerif',
                                fontSize: 30,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Escolha no baralho ou arraste uma carta.\nRevele no seu tempo.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          for (final c in cards)
            CardTravel(
              key: ValueKey('placed-layer-${s.readingId}-${c.cardId}'),
              destination: g.cardRect(c, s),
              origin: g.deck,
              releaseOrigin: _releaseOrigins[c.cardId] == null
                  ? null
                  : Rect.fromCenter(
                      center: _releaseOrigins[c.cardId]!,
                      width: g.width,
                      height: g.width * 5 / 3,
                    ),
              reducedMotion: reducedMotion,
              child: Opacity(
                opacity: _drag?.id == c.cardId ? 0 : 1,
                alwaysIncludeSemantics: true,
                child: _insight(
                  _meaning(s, c),
                  s,
                  placed: c,
                  child: Semantics(
                    label: c.revealed
                        ? '${deck.card(c.cardId).canonicalName}, revelada, abrir informações'
                        : 'Carta fechada ${c.drawIndex + 1}, revelar',
                    button: true,
                    child: _gesture(
                      id: c.cardId,
                      session: s,
                      geometry: g,
                      onTap: () => _cardTap(s, c),
                      child: RotatedBox(
                        quarterTurns: g.turns[c.slotId] ?? 0,
                        child: Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.none,
                          children: [
                            face(
                              c.cardId,
                              key: Key('card-${c.cardId}'),
                              animate: true,
                            ),
                            if (c.slotId == null)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    color: const Color(0xEE211A31),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        c.complementOf == null
                                            ? 'Carta ${c.drawIndex + 1}'
                                            : '${s.complementNumber(c)}° complemento',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFE4D7BC),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          for (var i = 0; i < slots.length; i++)
            Positioned.fromRect(
              rect: g.labels[slots[i].slotId]!,
              // Labels are decorative; the card/slot owns hover and gestures.
              child: IgnorePointer(
                child: Text(
                  slots[i].meaningKey,
                  key: Key('label-${slots[i].slotId}'),
                  maxLines: s.spread?.spreadId == 'CRUZ_HERMETICA' ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: math.min(11, math.max(8, g.width * .2)),
                    height: 1.05,
                    color: const Color(0xFFE4D7BC),
                  ),
                ),
              ),
            ),
          if (_drag != null)
            Positioned(
              key: const Key('feedback-layer'),
              left: _drag!.point.dx - g.width / 2,
              top: _drag!.point.dy - g.width * 5 / 6,
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: reducedMotion ? 1.0 : .85, end: 1.0),
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 140),
                  builder: (_, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: face(_drag!.id, key: const Key('drag-feedback')),
                ),
              ),
            ),
          Positioned.fromRect(
            key: const Key('deck-layer'),
            rect: g.deck,
            child: Semantics(
              label: 'Baralho, ${s.remaining} cartas restantes',
              button: true,
              child: _gesture(
                session: s,
                geometry: g,
                onTap: () => _choose(s),
                child: Opacity(
                  opacity: s.remaining == 0 ? .3 : 1,
                  child: face(
                    null,
                    key: const Key('deck'),
                    width: g.deck.width,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: g.deck.bottom + 3,
            right: 14,
            child: Text(
              '${s.remaining} / 78',
              style: const TextStyle(fontSize: 10),
            ),
          ),
          if (_selectedId != null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 4,
              child: Material(
                color: const Color(0xEE33263F),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Escolhida. Toque no destino.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: slots.isEmpty
                          ? 'Colocar no centro'
                          : 'Colocar na próxima posição',
                      onPressed: () {
                        final slot = slots
                            .where(
                              (x) => x.slotId == _controller.nextOpenSlotId,
                            )
                            .firstOrNull;
                        final index = s.drawOrder
                            .skip(s.placed.length)
                            .toList()
                            .indexOf(_selectedId!);
                        if (slot != null) {
                          _draw(
                            slot.position,
                            index: index,
                            slotId: slot.slotId,
                          );
                        } else {
                          _place(
                            Offset(
                              size.width / 2,
                              slots.isEmpty
                                  ? size.height / 2
                                  : size.height - 25 - g.width * 5 / 6,
                            ),
                            g,
                            s,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.add_card,
                        color: Color(0xFFD4BD87),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedId = null),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          if (s.remaining == 0)
            const Positioned(
              left: 16,
              bottom: 8,
              child: Text('Baralho esgotado'),
            ),
        ],
      ),
    );
  }
}
