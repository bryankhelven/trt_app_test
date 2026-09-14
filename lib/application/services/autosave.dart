import '../../domain/readings/reading_session.dart';
import '../ports/reading_repository.dart';

/// Save on committed actions, never on pointer-move frames. Serial writes prevent
/// an older snapshot finishing after a newer one. Errors reach each caller.
class Autosave {
  Autosave(this.repository);
  final ReadingRepository repository;
  Future<void> _tail = Future.value();
  Future<void> enqueue(ReadingSession session) {
    final operation = _tail.then((_) => repository.save(session));
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  Future<void> flush() => _tail;
}
