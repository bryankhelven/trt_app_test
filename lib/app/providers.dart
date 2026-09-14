import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/ad_service.dart';
import '../application/ports/purchase_service.dart';
import '../application/ports/reading_repository.dart';
import '../application/ports/settings_repository.dart';
import '../domain/cards/editorial_content.dart';
import '../domain/decks/tarot_deck.dart';
import '../domain/randomization/shuffle.dart';
import '../infrastructure/assets/development_deck.dart';
import '../infrastructure/monetization/mobile_ad_service.dart';
import '../infrastructure/monetization/store_purchase_service.dart';
import '../features/settings/settings_controller.dart';
import '../infrastructure/persistence/database.dart';
import '../infrastructure/persistence/open_database.dart';
import '../infrastructure/persistence/reading_repository.dart';
import '../infrastructure/persistence/settings_repository.dart';
import '../infrastructure/randomization/secure_random_source.dart';

/// Overridden in `main.dart` with the bundled Rider-Waite-Smith deck once
/// loaded from assets; the development placeholder deck remains the default
/// for tests that don't need real artwork/content.
final deckProvider = Provider<TarotDeck>((ref) => developmentDeck());

/// Overridden in `main.dart` with the loaded PT-BR editorial corpus.
final editorialContentProvider = Provider<Map<String, EditorialContent>>(
  (ref) => const {},
);
final randomProvider = Provider<RandomSource>((ref) => SecureRandomSource());
final clockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = openDatabase();
  ref.onDispose(() => db.close());
  return db;
});
final readingRepositoryProvider = Provider<ReadingRepository>(
  (ref) => SqlReadingRepository(ref.watch(appDatabaseProvider)),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SqlSettingsRepository(ref.watch(appDatabaseProvider)),
);

const storeEnabled = bool.fromEnvironment('ENABLE_STORE');
const bannerUnitId = String.fromEnvironment('ANDROID_BANNER_ID');
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  if (!storeEnabled ||
      kIsWeb ||
      ![
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform)) {
    return const StoreUnavailable();
  }
  final service = StorePurchaseService(
    ref.watch(settingsRepositoryProvider),
    onChanged: () => ref.invalidate(settingsControllerProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
final adServiceProvider = Provider.autoDispose<AdService>((ref) {
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android ||
      bannerUnitId.isEmpty) {
    return const NoAds();
  }
  final service = MobileBannerService(bannerUnitId);
  ref.onDispose(service.dispose);
  return service;
});
