import '../../application/ports/ad_service.dart';

/// Local test double for the ad SDK adapter, using test placement
/// configuration only (see docs/spec/07 M-007). Swap for a real banner/
/// native AdMob adapter before release; see KNOWN_LIMITATIONS.md. Tracks
/// [requestCount] so tests can assert `remove_ads` stops ad requests
/// entirely, not just hides the widget.
class FakeAdService implements AdService {
  int requestCount = 0;
  bool _ready = false;
  @override
  bool get bannerReady => _ready;
  @override
  Future<void> loadBanner() async {
    requestCount++;
    _ready = true;
  }
}
