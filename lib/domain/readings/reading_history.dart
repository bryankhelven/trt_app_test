import 'reading_session.dart';

/// Revelation is a barrier: it cannot be undone, nor can that draw be returned.
class ReadingHistory {
  ReadingHistory(this.current);
  ReadingSession current;
  final _past = <ReadingSession>[];
  final _future = <ReadingSession>[];
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  void apply(ReadingSession next) {
    if (next.readingId != current.readingId) {
      throw ArgumentError('Different reading');
    }
    if (identical(next, current)) return;
    final known = current.placed
        .where((c) => c.revealed)
        .map((c) => c.cardId)
        .toSet();
    if (next.placed.any((c) => c.revealed && !known.contains(c.cardId))) {
      _past.clear();
    } else {
      _past.add(current);
    }
    _future.clear();
    current = next;
  }

  void undo() {
    if (canUndo) {
      _future.add(current);
      current = _past.removeLast();
    }
  }

  void redo() {
    if (canRedo) {
      _past.add(current);
      current = _future.removeLast();
    }
  }
}
