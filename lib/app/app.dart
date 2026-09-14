import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/settings_controller.dart';
import 'routing/router.dart';
import 'theme/theme.dart';

class TarotApp extends ConsumerWidget {
  const TarotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    final reducedMotion = settings?.reducedMotion ?? false;
    ThemeData applyMotion(ThemeData base) => reducedMotion
        ? base.copyWith(pageTransitionsTheme: reducedMotionPageTransitionsTheme)
        : base;
    return MaterialApp.router(
      title: 'Arcanum',
      debugShowCheckedModeBanner: false,
      themeMode: settings?.themeMode ?? ThemeMode.dark,
      theme: applyMotion(tarotLightTheme),
      darkTheme: applyMotion(tarotTheme),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
