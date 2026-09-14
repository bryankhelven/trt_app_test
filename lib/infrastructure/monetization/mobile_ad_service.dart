import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../application/ports/ad_service.dart';

class NoAds implements AdService {
  const NoAds();
  @override
  bool get bannerReady => false;
  @override
  Future<void> loadBanner() async {}
}

/// Only a banner can be created by this adapter. Consent must succeed first.
class MobileBannerService implements AdService {
  MobileBannerService(this.unitId);
  final String unitId;
  BannerAd? banner;
  bool _disposed = false;
  @override
  bool get bannerReady => banner != null;
  @override
  Future<void> loadBanner() async {
    final consent = Completer<bool>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        ConsentForm.loadAndShowConsentFormIfRequired((error) async {
          if (!consent.isCompleted) {
            consent.complete(
              error == null &&
                  await ConsentInformation.instance.canRequestAds(),
            );
          }
        });
      },
      (_) {
        if (!consent.isCompleted) consent.complete(false);
      },
    );
    if (!await consent.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () => false,
        ) ||
        _disposed) {
      return;
    }
    await MobileAds.instance.initialize();
    if (_disposed) return;
    final done = Completer<void>();
    final ad = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
          } else {
            banner = ad as BannerAd;
          }
          if (!done.isCompleted) done.complete();
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!done.isCompleted) done.complete();
        },
      ),
    );
    await ad.load();
    await done.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        ad.dispose();
      },
    );
  }

  void dispose() {
    _disposed = true;
    banner?.dispose();
    banner = null;
  }
}
