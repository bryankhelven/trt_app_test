/// Local-first key-value store backing Settings and monetization
/// entitlements. Never synced, never sent to analytics.
abstract interface class SettingsRepository {
  Future<Map<String, String>> loadAll();
  Future<void> set(String key, String value);
}
