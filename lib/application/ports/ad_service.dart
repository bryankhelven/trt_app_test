/// Ad adapter boundary. Only banner/native formats are ever allowed here —
/// no interstitial/rewarded-interstitial/app-open/fullscreen format may be
/// added to this interface; see docs/spec/07 M-002. Callers must never
/// invoke this for a reading-table screen and must never call it when the
/// viewer holds the `remove_ads` entitlement.
abstract interface class AdService {
  Future<void> loadBanner();
  bool get bannerReady;
}
