import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tarot_app/infrastructure/monetization/store_purchase_service.dart';
import 'package:tarot_app/application/ports/settings_repository.dart';

class Settings implements SettingsRepository {
  final values = <String, String>{};
  @override
  Future<Map<String, String>> loadAll() async => Map.of(values);
  @override
  Future<void> set(String key, String value) async {
    values[key] = value;
  }
}

class Store implements InAppPurchase {
  final events = StreamController<List<PurchaseDetails>>.broadcast();
  PurchaseStatus outcome = PurchaseStatus.purchased;
  int completed = 0;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => events.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [
          ProductDetails(
            id: 'remove_ads',
            title: 'Remover anúncios',
            description: 'Uma compra',
            price: 'R\$ 9,90',
            rawPrice: 9.90,
            currencyCode: 'BRL',
          ),
        ],
        notFoundIDs: [],
      );
  PurchaseDetails event(PurchaseStatus status) => PurchaseDetails(
    purchaseID: 'test-transaction',
    productID: 'remove_ads',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'receipt',
      source: 'test',
    ),
    transactionDate: '1',
    status: status,
  )..pendingCompletePurchase = true;
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    events.add([event(outcome)]);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed++;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    events.add([event(PurchaseStatus.restored)]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final status in [
    PurchaseStatus.purchased,
    PurchaseStatus.canceled,
    PurchaseStatus.error,
  ]) {
    test('Store $status grants entitlement only on purchase event', () async {
      final settings = Settings();
      final store = Store()..outcome = status;
      final service = StorePurchaseService(settings, store: store);
      final success = await service.purchase('remove_ads');
      expect(success, status == PurchaseStatus.purchased);
      expect(
        settings.values['entitlement:remove_ads'],
        success ? 'true' : null,
      );
      expect(store.completed, success ? 1 : 0);
      service.dispose();
      await store.events.close();
    });
  }
  test('Restored store event persists entitlement before result', () async {
    final settings = Settings();
    final store = Store();
    final service = StorePurchaseService(settings, store: store);
    expect(await service.restore(), {'remove_ads'});
    expect(store.completed, 1);
    service.dispose();
    await store.events.close();
  });
  test('Unconfigured store cannot grant a simulated purchase', () async {
    expect(
      () => const StoreUnavailable().purchase('remove_ads'),
      throwsStateError,
    );
  });
}
