import '../../domain/readings/reading_session.dart';

abstract interface class ReadingRepository {
  Future<void> save(ReadingSession session);
  Future<ReadingSession?> read(String id);

  /// The in-progress (not-yet-replaced) session for a given reading mode.
  /// `mode` is a [ReadingSession.spreadId] value ('FREE' or a spread id):
  /// each mode keeps its own independent active session.
  Future<ReadingSession?> active({String mode = 'FREE'});
  Future<List<ReadingSession>> list();
  Future<void> delete(String id);
}

class CorruptReading implements Exception {
  @override
  String toString() =>
      'Não foi possível restaurar a leitura. Os dados foram preservados.';
}
