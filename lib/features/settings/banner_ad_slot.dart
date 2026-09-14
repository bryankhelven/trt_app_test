import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../infrastructure/monetization/mobile_ad_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'settings_controller.dart';

/// Banner in its own footer below the reading canvas; never covers cards.
class BannerAdSlot extends ConsumerStatefulWidget {
  const BannerAdSlot({super.key});
  @override
  ConsumerState<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<BannerAdSlot> {
  bool _requested = false;
  bool _ready = false;

  Future<void> _request() async {
    _requested = true;
    final service = ref.read(adServiceProvider);
    try {
      await service.loadBanner();
    } on Object {
      return;
    }
    if (mounted) setState(() => _ready = service.bannerReady);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    ref.watch(adServiceProvider);
    final entitled = settings.value?.removeAdsEntitled ?? true;
    if (entitled) return const SizedBox.shrink();
    if (!_requested) {
      _request();
    }
    if (!_ready) return const SizedBox.shrink();
    final service = ref.read(adServiceProvider);
    if (service is MobileBannerService && service.banner != null) {
      final banner = service.banner!;
      return SizedBox(
        key: const Key('banner-ad-slot'),
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      );
    }
    return Container(
      key: const Key('banner-ad-slot'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        'Anúncio (teste)',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
