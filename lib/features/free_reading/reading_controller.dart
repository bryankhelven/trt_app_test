import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../home/home_screen.dart';
import '../journal/journal_screen.dart';
import '../../domain/randomization/shuffle.dart';
import '../../domain/readings/reading_history.dart';
import '../../domain/readings/reading_session.dart';
import '../../domain/spreads/spread_catalog.dart';
import '../../domain/spreads/spread_definition.dart';

class ReadingView {
  const ReadingView(
    this.session, {
    this.saving = false,
    this.saveFailed = false,
    this.saved = false,
  });
  final ReadingSession session;
  final bool saving, saveFailed, saved;
}

typedef ReadingControllerProvider =
    AsyncNotifierProvider<ReadingController, ReadingView>;

/// Riverpod 3 dropped manual `.family`; the catalog of reading modes is
/// small and static, so one provider is declared per mode instead of a
/// dynamic family. Each mode keeps its own independent active session.
final ReadingControllerProvider readingControllerProvider =
    AsyncNotifierProvider(() => ReadingController(null));

final Map<String, ReadingControllerProvider> spreadReadingControllerProviders =
    {
      for (final mode in SpreadCatalog.modes)
        if (mode.spread != null)
          mode.id: AsyncNotifierProvider(() => ReadingController(mode.spread)),
    };

/// Provider for a given mode id ('FREE' or a [SpreadCatalog] spread id).
ReadingControllerProvider readingControllerProviderFor(String modeId) =>
    modeId == 'FREE'
    ? readingControllerProvider
    : spreadReadingControllerProviders[modeId]!;

class ReadingController extends AsyncNotifier<ReadingView> {
  ReadingController(this._spread, {this.initialSession});
  final ReadingSession? initialSession;
  SpreadDefinition? _spread;
  late ReadingHistory _history;
  ReadingSession? _savedSnapshot;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  DateTime get _now => ref.read(clockProvider)();
  @override
  Future<ReadingView> build() async {
    _savedSnapshot = initialSession;
    final session = initialSession ?? _newSession();
    _history = ReadingHistory(session);
    return ReadingView(session, saved: initialSession != null);
  }

  Future<void> setPaired(bool enabled) async {
    if (_spread == null || _history.current.placed.isNotEmpty) {
      throw StateError('Configure os pares antes de retirar cartas.');
    }
    final base = SpreadCatalog.byId(_spread!.spreadId).spread!;
    _spread = enabled ? SpreadCatalog.withPairs(base) : base;
    final previous = _history.current;
    _history = ReadingHistory(
      _newSession().annotate(
        question: previous.question,
        notes: previous.notes,
        now: _now,
      ),
    );
    await _publish(_history.current);
  }

  ReadingSession _newSession() {
    final deck = ref.read(deckProvider);
    final random = ref.read(randomProvider);
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return ReadingSession.start(
      readingId: id,
      deck: deck,
      drawOrder: shuffle(deck.cardIds, random),
      now: _now,
      spread: _spread,
    );
  }

  Future<void> _publish(ReadingSession session) async {
    state = AsyncData(
      ReadingView(session, saved: identical(session, _savedSnapshot)),
    );
  }

  Future<void> saveExplicitly() async {
    if (state.value?.saving == true) return;
    final snapshot = _history.current;
    state = AsyncData(ReadingView(snapshot, saving: true));
    try {
      await ref.read(readingRepositoryProvider).save(snapshot);
      if (!ref.mounted) return;
      _savedSnapshot = snapshot;
      ref.invalidate(recentReadingsProvider);
      ref.invalidate(journalProvider);
      await _publish(_history.current);
    } on Object {
      if (ref.mounted) {
        state = AsyncData(ReadingView(_history.current, saveFailed: true));
      }
    }
  }

  Future<void> _apply(ReadingSession next) {
    _history.apply(next);
    return _publish(next);
  }

  /// Next unfilled slot in declaration order, for predefined spreads.
  String? get nextOpenSlotId {
    final spread = _spread;
    if (spread == null) return null;
    final filled = _history.current.placed.map((c) => c.slotId).toSet();
    for (final slot in spread.slots) {
      if (!filled.contains(slot.slotId)) return slot.slotId;
    }
    return null;
  }

  Future<void> draw(
    TablePosition position, {
    String? slotId,
    String? complementOf,
    int index = 0,
  }) async {
    if (_history.current.remaining == 0) return;
    final slot = _spread?.slots.where((s) => s.slotId == slotId).firstOrNull;
    if (slot?.requiredArcana != null) {
      final id = _history.current.drawOrder
          .skip(_history.current.placed.length)
          .elementAt(index);
      if (ref.read(deckProvider).card(id).arcanaType != slot!.requiredArcana) {
        throw StateError(
          'Escolha um arcano ${slot.requiredArcana!.name == 'major' ? 'maior' : 'menor'} para esta posição.',
        );
      }
    }
    await _apply(
      _history.current.chooseCard(
        index,
        position,
        _now,
        slotId: slotId,
        complementOf: complementOf,
      ),
    );
  }

  Future<void> move(
    String id,
    TablePosition position, {
    String? slotId,
    String? complementOf,
  }) async {
    final slot = _spread?.slots.where((s) => s.slotId == slotId).firstOrNull;
    if (slot?.requiredArcana != null &&
        ref.read(deckProvider).card(id).arcanaType != slot!.requiredArcana) {
      throw StateError(
        'Escolha um arcano ${slot.requiredArcana!.name == 'major' ? 'maior' : 'menor'} para esta posição.',
      );
    }
    await _apply(
      _history.current.move(
        id,
        position,
        _now,
        slotId: slotId,
        complementOf: complementOf,
      ),
    );
  }

  Future<void> reveal(String id) => _apply(_history.current.reveal(id, _now));
  Future<void> annotate(String question, String notes) => _apply(
    _history.current.annotate(question: question, notes: notes, now: _now),
  );
  Future<void> retry() => saveExplicitly();
  Future<void> undo() {
    _history.undo();
    return _publish(_history.current);
  }

  Future<void> redo() {
    _history.redo();
    return _publish(_history.current);
  }

  Future<void> newReading() {
    _history = ReadingHistory(_newSession());
    return _publish(_history.current);
  }

  Future<void> reorderRemaining(List<String> ids) =>
      _apply(_history.current.reorderRemaining(ids, _now));

  Future<void> shuffleRemaining() => _apply(
    _history.current.reorderRemaining(
      shuffle(
        _history.current.drawOrder.skip(_history.current.placed.length),
        ref.read(randomProvider),
      ),
      _now,
    ),
  );
  Future<void> cutRemaining([int? point]) {
    final rest = _history.current.drawOrder
        .skip(_history.current.placed.length)
        .toList();
    return _apply(
      _history.current.reorderRemaining(
        cut(rest, point ?? rest.length ~/ 2),
        _now,
      ),
    );
  }
}
