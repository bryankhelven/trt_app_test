import '../../application/ports/settings_repository.dart';
import 'database.dart';

class SqlSettingsRepository implements SettingsRepository {
  SqlSettingsRepository(this.db);
  final AppDatabase db;

  @override
  Future<Map<String, String>> loadAll() async {
    final rows = await db.select(db.settings).get();
    return {for (final r in rows) r.key: r.value};
  }

  @override
  Future<void> set(String key, String value) => db
      .into(db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
