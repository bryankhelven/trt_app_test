/// Entitlement ids used by the store adapter. Kept as ids (not booleans) so
/// future premium feature packs and deck packs don't require new adapter
/// methods; see docs/spec/07 M-004.
const removeAdsEntitlement = 'remove_ads';

/// Billing adapter boundary. Production Android builds must back this with
/// Google Play Billing; v1 ships [FakePurchaseService] (a local, always-
/// succeeding test double) so the entitlement flow, Settings UI and tests
/// are complete before Play Console/store-sandbox access is available. See
/// KNOWN_LIMITATIONS.md.
abstract interface class PurchaseService {
  Future<bool> purchase(String entitlementId);
  Future<Set<String>> restore();
}
