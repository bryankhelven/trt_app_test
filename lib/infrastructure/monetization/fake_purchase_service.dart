import '../../application/ports/purchase_service.dart';
import '../../application/ports/settings_repository.dart';

/// Local test double for the store adapter: purchase and restore both
/// succeed immediately and persist the entitlement locally. Swap for a real
/// Google Play Billing adapter before release; see
/// docs/spec/07_MONETIZATION_PRIVACY_AND_CREDITS.md M-003 and
/// KNOWN_LIMITATIONS.md.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService(this._settings);
  final SettingsRepository _settings;
  static String _key(String id) => 'entitlement:$id';

  @override
  Future<bool> purchase(String entitlementId) async {
    await _settings.set(_key(entitlementId), 'true');
    return true;
  }

  @override
  Future<Set<String>> restore() async {
    final all = await _settings.loadAll();
    return {
      for (final entry in all.entries)
        if (entry.key.startsWith('entitlement:') && entry.value == 'true')
          entry.key.substring('entitlement:'.length),
    };
  }
}
