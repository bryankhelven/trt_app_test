import 'package:flutter/material.dart';

const _brassAccent = Color(0xFFCAB78A);
const _brassAccentBright = Color(0xFFE0CE9E);
const _ink = Color(0xFF101020);

const _darkBackground = Color(0xFF0C0B18);
const _darkSurface = Color(0xFF181527);
const _darkSurfaceVariant = Color(0xFF29213B);
const _darkOnSurface = Color(0xFFE9E4D6);
const _parchment = Color(0xFFF3ECDA);
const _parchmentInk = Color(0xFF241C10);

const _lightBackground = Color(0xFFFBF8EF);
const _lightSurface = Color(0xFFF6F1E4);
const _lightSurfaceVariant = Color(0xFFEDE4CC);
const _lightPrimary = Color(0xFF332440);
const _lightOnSurface = Color(0xFF241C10);

const _headlineFontFamily = 'ArcanumSerif';
const _headlineFontFamilyFallback = ['serif4', 'serif'];

const _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _brassAccent,
  onPrimary: _ink,
  primaryContainer: Color(0xFF332440),
  onPrimaryContainer: _brassAccentBright,
  secondary: Color(0xFFAB9AC3),
  onSecondary: _ink,
  secondaryContainer: _darkSurfaceVariant,
  onSecondaryContainer: _darkOnSurface,
  tertiary: _brassAccentBright,
  onTertiary: _ink,
  error: Color(0xFFCF6679),
  onError: _ink,
  errorContainer: Color(0xFF4C2229),
  onErrorContainer: Color(0xFFF3C6CC),
  surface: _darkSurface,
  onSurface: _darkOnSurface,
  surfaceContainerHighest: _darkSurfaceVariant,
  onSurfaceVariant: Color(0xFFC5BED0),
  outline: Color(0xFF71627E),
  outlineVariant: Color(0xFF3B324B),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: _parchment,
  onInverseSurface: _parchmentInk,
  inversePrimary: Color(0xFF4C6152),
  surfaceTint: _brassAccent,
);

const _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: _lightPrimary,
  onPrimary: Color(0xFFF6F1E4),
  primaryContainer: Color(0xFFDCE7DD),
  onPrimaryContainer: Color(0xFF181527),
  secondary: Color(0xFF8A6D2C),
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFEFE1BC),
  onSecondaryContainer: Color(0xFF3A2E0F),
  tertiary: Color(0xFF8A6D2C),
  onTertiary: Colors.white,
  error: Color(0xFFB3261E),
  onError: Colors.white,
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  surface: _lightSurface,
  onSurface: _lightOnSurface,
  surfaceContainerHighest: _lightSurfaceVariant,
  onSurfaceVariant: Color(0xFF554A32),
  outline: Color(0xFFAA986E),
  outlineVariant: Color(0xFFD8CBA4),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: Color(0xFF181527),
  onInverseSurface: _parchment,
  inversePrimary: _brassAccent,
  surfaceTint: _lightPrimary,
);

TextTheme _textTheme(ColorScheme scheme) {
  final base = ThemeData(colorScheme: scheme, useMaterial3: true).textTheme;
  TextStyle? display(TextStyle? s) => s?.copyWith(
    fontFamily: _headlineFontFamily,
    fontFamilyFallback: _headlineFontFamilyFallback,
    letterSpacing: .2,
  );
  return base.copyWith(
    displayLarge: display(base.displayLarge),
    displayMedium: display(base.displayMedium),
    displaySmall: display(base.displaySmall),
    headlineLarge: display(base.headlineLarge),
    headlineMedium: display(base.headlineMedium),
    headlineSmall: display(base.headlineSmall),
    titleLarge: display(base.titleLarge),
  );
}

ThemeData _buildTheme(ColorScheme scheme, Color scaffoldBackground) {
  final textTheme = _textTheme(scheme);
  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBackground,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: scheme.brightness == Brightness.dark ? 3 : 1,
      shadowColor: Colors.black54,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant, width: .6),
      ),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      textColor: scheme.onSurface,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        color: scheme.onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: scheme.primary,
      backgroundColor: scheme.surfaceContainerHighest,
      labelStyle: TextStyle(color: scheme.onSurface),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
  );
}

final tarotTheme = _buildTheme(_darkColorScheme, _darkBackground);

final tarotLightTheme = _buildTheme(_lightColorScheme, _lightBackground);

/// Applied instead of the default platform page transitions when the
/// viewer enabled "Reduzir animações" in Settings.
final reducedMotionPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: const _NoAnimationPageTransitionsBuilder(),
  },
);

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
