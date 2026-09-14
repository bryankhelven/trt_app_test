import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/app/app.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/application/ports/purchase_service.dart';
import 'package:tarot_app/application/ports/settings_repository.dart';
import 'package:tarot_app/features/settings/settings_controller.dart';
import 'package:tarot_app/infrastructure/monetization/fake_ad_service.dart';

class InMemorySettingsRepository implements SettingsRepository {
  final Map<String, String> store = {};
  @override
  Future<Map<String, String>> loadAll() async => Map.of(store);
  @override
  Future<void> set(String k, String v) async => store[k] = v;
}

void main() {
  testWidgets(
    'R2 banner is below reading canvas, absent on Home, removed by entitlement',
    (tester) async {
      final repo = InMemorySettingsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repo),
            adServiceProvider.overrideWithValue(FakeAdService()),
          ],
          child: const TarotApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner-ad-slot')), findsNothing);
      await tester.tap(find.byKey(const Key('start-free')));
      await tester.pumpAndSettle();
      final banner = find.byKey(const Key('banner-ad-slot'));
      expect(banner, findsOneWidget);
      expect(
        tester.getRect(banner).top,
        greaterThanOrEqualTo(
          tester.getRect(find.byKey(const Key('table'))).bottom,
        ),
      );
      await repo.set('entitlement:$removeAdsEntitlement', 'true');
      ProviderScope.containerOf(tester.element(find.byType(TarotApp)))
          .invalidate(settingsControllerProvider);
      await tester.pumpAndSettle();
      expect(banner, findsNothing);
    },
  );
}
