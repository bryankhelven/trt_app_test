import 'package:drift/drift.dart';
part 'database.g.dart';

class Readings extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  IntColumn get updatedAt => integer()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ActiveReadings extends Table {
  TextColumn get id => text()();
  TextColumn get readingId => text().references(Readings, #id)();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Generic local key-value store for app Settings (theme, reduced motion)
/// and monetization entitlements (e.g. `entitlement:remove_ads`). Kept as a
/// single flexible table rather than one column per setting so adding a
/// setting never requires another migration.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Readings, ActiveReadings, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  @override
  int get schemaVersion => 4;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 1 || from > 4 || to != 4) {
        throw StateError('Unsupported database version');
      }
      if (from == 1) {
        await m.createTable(activeReadings);
        await customStatement(
          "INSERT INTO active_readings (id, reading_id) SELECT 'active', id FROM readings ORDER BY updated_at DESC, id DESC LIMIT 1",
        );
      }
      if (from <= 2) {
        // Prior schema versions only ever stored the Free Reading mode under
        // the single hardcoded key 'active'; v3 keys active sessions by
        // reading mode (ReadingSession.spreadId) so each predefined spread
        // keeps its own independent in-progress session.
        await customStatement(
          "UPDATE active_readings SET id = 'FREE' WHERE id = 'active'",
        );
      }
      if (from <= 3) {
        await m.createTable(settings);
      }
    },
    beforeOpen: (details) async {
      if (details.versionNow != schemaVersion) {
        throw StateError('Unsupported database version');
      }
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
