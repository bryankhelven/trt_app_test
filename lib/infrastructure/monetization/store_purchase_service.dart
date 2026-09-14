import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../application/ports/purchase_service.dart';
import '../../application/ports/settings_repository.dart';

class StoreUnavailable implements PurchaseService {
  const StoreUnavailable();
  @override
  Future<bool> purchase(String entitlementId) async =>
      throw StateError('Store unavailable');
  @override
  Future<Set<String>> restore() async => throw StateError('Store unavailable');
}

/// One non-consumable product. Native purchase events are the only source of
/// grants; starting checkout, pending and canceled events never grant access.
/// Enable only for store sandbox/release builds after product configuration.
/// Local entitlement cache is not a server receipt-verification system.
class StorePurchaseService implements PurchaseService {
  StorePurchaseService(this.settings, {InAppPurchase? store, this.onChanged})
    : store = store ?? InAppPurchase.instance {
    _subscription = this.store.purchaseStream.listen(
      (events) {
        _queue = _queue.then((_) => _handle(events)).catchError((Object _) {
          if (_purchase?.isCompleted == false) _purchase!.complete(false);
        });
      },
      onError: (Object _) {
        if (_purchase?.isCompleted == false) _purchase!.complete(false);
      },
    );
  }
  final SettingsRepository settings;
  final InAppPurchase store;
  final void Function()? onChanged;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  Future<void> _queue = Future.value();
  Completer<bool>? _purchase;
  bool _busy = false;
  static const productId = String.fromEnvironment(
    'REMOVE_ADS_PRODUCT',
    defaultValue: 'remove_ads',
  );

  Future<void> _handle(List<PurchaseDetails> events) async {
    for (final event in events) {
      if (event.productID != productId) continue;
      switch (event.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (event.purchaseID == null ||
              event.verificationData.serverVerificationData.isEmpty) {
            if (_purchase?.isCompleted == false) _purchase!.complete(false);
            continue;
          }
          await settings.set('entitlement:$removeAdsEntitlement', 'true');
          if (event.pendingCompletePurchase) {
            await store.completePurchase(event);
          }
          onChanged?.call();
          if (_purchase?.isCompleted == false) _purchase!.complete(true);
        case PurchaseStatus.canceled:
        case PurchaseStatus.error:
          if (_purchase?.isCompleted == false) _purchase!.complete(false);
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  @override
  Future<bool> purchase(String entitlementId) async {
    if (entitlementId != removeAdsEntitlement || _busy) return false;
    _busy = true;
    try {
      if (!await store.isAvailable()) throw StateError('Store unavailable');
      final products = await store.queryProductDetails({productId});
      if (products.error != null || products.productDetails.isEmpty) {
        throw StateError('Product unavailable');
      }
      _purchase = Completer<bool>();
      final started = await store.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: products.productDetails.single,
        ),
      );
      if (!started) return false;
      return await _purchase!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => false,
      );
    } finally {
      _busy = false;
      _purchase = null;
    }
  }

  @override
  Future<Set<String>> restore() async {
    if (_busy) throw StateError('Store busy');
    _busy = true;
    try {
      if (!await store.isAvailable()) throw StateError('Store unavailable');
      await store.restorePurchases();
      // Let the native stream's queued microtask enqueue its serial processing.
      await Future<void>.delayed(Duration.zero);
      await _queue;
      final values = await settings.loadAll();
      return {
        if (values['entitlement:$removeAdsEntitlement'] == 'true')
          removeAdsEntitlement,
      };
    } finally {
      _busy = false;
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
