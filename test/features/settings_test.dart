import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/app/app.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/application/ports/purchase_service.dart';
import 'package:tarot_app/application/ports/settings_repository.dart';
import 'package:tarot_app/infrastructure/monetization/fake_purchase_service.dart';

/// In-memory [SettingsRepository] so tests can hold a reference to the
/// backing store across a simulated app restart (a fresh [ProviderScope]/
/// widget tree, same repository instance) without touching a real
/// database — mirrors the `MemoryReadings` pattern in journal_test.dart.
class InMemorySettingsRepository implements SettingsRepository {
  final Map<String, String> store = {};
  @override
  Future<Map<String, String>> loadAll() async => Map.of(store);
  @override
  Future<void> set(String key, String value) async => store[key] = value;
}

/// Scrolls the Settings list until [finder] is built and on-screen; the
/// screen has grown enough sections that later items (licenses, restore
/// purchases, version) aren't mounted by the sliver list until scrolled
/// into the cache area.
Future<void> scrollToVisible(WidgetTester tester, Finder finder) => tester
    .dragUntilVisible(finder, find.byType(Scrollable), const Offset(0, -200));

Future<void> pumpSettings(
  WidgetTester tester,
  SettingsRepository repo, {
  PurchaseService? purchaseService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
        purchaseServiceProvider.overrideWithValue(
          purchaseService ?? FakePurchaseService(repo),
        ),
      ],
      child: const TarotApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Configurações'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Configurações'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Reduced motion persists across restart', (tester) async {
    final repo = InMemorySettingsRepository();
    await pumpSettings(tester, repo);
    await tester.tap(find.byKey(const Key('reduced-motion-switch')));
    await tester.pumpAndSettle();
    expect(repo.store['reduced_motion'], 'true');
    await pumpSettings(tester, repo);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('reduced-motion-switch')),
          )
          .value,
      isTrue,
    );
    expect(find.byKey(const Key('sound-switch')), findsNothing);
    expect(find.byKey(const Key('haptics-switch')), findsNothing);
  });

  testWidgets('Theme choice persists across a simulated app restart', (
    tester,
  ) async {
    final repo = InMemorySettingsRepository();
    await pumpSettings(tester, repo);

    await tester.tap(find.byKey(const Key('theme-light')));
    await tester.pumpAndSettle();
    expect(repo.store['theme_mode'], 'light');

    await pumpSettings(tester, repo);
    final group = tester.widget<RadioGroup<ThemeMode>>(
      find.byType(RadioGroup<ThemeMode>),
    );
    expect(group.groupValue, ThemeMode.light);
  });

  testWidgets('Tapping "Licenças de bibliotecas de terceiros" opens the '
      'license page', (tester) async {
    final repo = InMemorySettingsRepository();
    await pumpSettings(tester, repo);

    await scrollToVisible(tester, find.byKey(const Key('open-licenses')));
    await tester.tap(find.byKey(const Key('open-licenses')));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets(
    'Restore purchases is tappable, never crashes, and acknowledges when '
    'nothing is found — the real store adapter lands in M11',
    (tester) async {
      final repo = InMemorySettingsRepository();
      await pumpSettings(tester, repo);

      await scrollToVisible(tester, find.byKey(const Key('restore-purchases')));
      expect(find.byKey(const Key('restore-purchases')), findsOneWidget);
      await tester.tap(find.byKey(const Key('restore-purchases')));
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhuma compra encontrada para restaurar.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Purchasing remove_ads persists the entitlement and restore then finds it',
    (tester) async {
      final repo = InMemorySettingsRepository();
      await pumpSettings(tester, repo);

      await scrollToVisible(
        tester,
        find.byKey(const Key('remove-ads-purchase')),
      );
      await tester.tap(find.byKey(const Key('remove-ads-purchase')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('remove-ads-active')), findsOneWidget);
      expect(repo.store['entitlement:$removeAdsEntitlement'], 'true');
      // Let the "Anúncios removidos." snackbar finish so it doesn't
      // intercept the next tap.
      await tester.pump(const Duration(seconds: 5));

      await scrollToVisible(tester, find.byKey(const Key('restore-purchases')));
      await tester.tap(find.byKey(const Key('restore-purchases')));
      await tester.pumpAndSettle();
      expect(find.text('Compras restauradas.'), findsOneWidget);
    },
  );

  testWidgets('App version is shown, read from a single source of truth', (
    tester,
  ) async {
    final repo = InMemorySettingsRepository();
    await pumpSettings(tester, repo);
    await scrollToVisible(tester, find.text('1.0.0+1'));
    expect(find.text('1.0.0+1'), findsOneWidget);
  });

  testWidgets(
    'No reversed-cards setting exists anywhere in Settings (hard domain '
    'rule DR-005)',
    (tester) async {
      final repo = InMemorySettingsRepository();
      await pumpSettings(tester, repo);

      expect(find.textContaining('invertid', findRichText: true), findsNothing);
      expect(find.textContaining('Invertid', findRichText: true), findsNothing);
      expect(find.textContaining('revers', findRichText: true), findsNothing);
      expect(find.textContaining('Revers', findRichText: true), findsNothing);
    },
  );
}
