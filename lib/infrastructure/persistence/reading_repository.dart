import 'package:drift/drift.dart';

import '../../application/ports/reading_repository.dart';
import '../../domain/readings/reading_session.dart';
import 'database.dart';
import 'reading_codec.dart';

class SqlReadingRepository implements ReadingRepository {
  SqlReadingRepository(this.db);
  final AppDatabase db;
  @override
  Future<void> save(ReadingSession session) => db.persistedTransaction(() async {
    await db
        .into(db.readings)
        .insertOnConflictUpdate(
          ReadingsCompanion.insert(
            id: session.readingId,
            payload: ReadingCodec.encode(session),
            updatedAt: session.updatedAt.millisecondsSinceEpoch,
          ),
        );
    await db
        .into(db.activeReadings)
        .insertOnConflictUpdate(
          ActiveReadingsCompanion.insert(
            id: session.spreadId,
            readingId: session.readingId,
          ),
        );
  });
  @override
  Future<ReadingSession?> read(String id) async {
    final row = await (db.select(
      db.readings,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    return row == null ? null : ReadingCodec.decode(row.payload);
  }

  @override
  Future<ReadingSession?> active({String mode = 'FREE'}) async {
    final row = await (db.select(
      db.activeReadings,
    )..where((r) => r.id.equals(mode))).getSingleOrNull();
    return row == null ? null : read(row.readingId);
  }

  @override
  Future<List<ReadingSession>> list() async => [
    for (final row in await (db.select(
      db.readings,
    )..orderBy([(r) => OrderingTerm.desc(r.updatedAt)])).get())
      ReadingCodec.decode(row.payload),
  ];
  @override
  Future<void> delete(String id) => db.persistedTransaction(() async {
    await (db.delete(
      db.activeReadings,
    )..where((r) => r.readingId.equals(id))).go();
    await (db.delete(db.readings)..where((r) => r.id.equals(id))).go();
  });
}
