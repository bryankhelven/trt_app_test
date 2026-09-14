import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../application/ports/purchase_service.dart';

const _themeKey = 'theme_mode';
const _reducedMotionKey = 'reduced_motion';
const _soundKey = 'sound_enabled';
const _hapticsKey = 'haptics_enabled';

ThemeMode _parseThemeMode(String? value) => switch (value) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  'system' => ThemeMode.system,
  _ => ThemeMode.dark,
};

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.reducedMotion,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.removeAdsEntitled,
  });
  final ThemeMode themeMode;
  final bool reducedMotion, soundEnabled, hapticsEnabled, removeAdsEntitled;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? reducedMotion,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? removeAdsEntitled,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    removeAdsEntitled: removeAdsEntitled ?? this.removeAdsEntitled,
  );
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final values = await ref.watch(settingsRepositoryProvider).loadAll();
    return SettingsState(
      themeMode: _parseThemeMode(values[_themeKey]),
      reducedMotion: values[_reducedMotionKey] == 'true',
      // Default on: no sound/haptic feedback is wired into gameplay yet
      // (v1 scope), but the preference itself defaults to enabled so
      // turning it on requires no action once real feedback lands.
      soundEnabled: values[_soundKey] != 'false',
      hapticsEnabled: values[_hapticsKey] != 'false',
      removeAdsEntitled: values['entitlement:$removeAdsEntitlement'] == 'true',
    );
  }

  Future<void> _update(
    String key,
    bool value,
    SettingsState Function(bool) apply,
  ) async {
    await ref.read(settingsRepositoryProvider).set(key, value.toString());
    final current = state.value;
    if (current != null) {
      state = AsyncData(apply(value));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref.read(settingsRepositoryProvider).set(_themeKey, mode.name);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(themeMode: mode));
    }
  }

  Future<void> setReducedMotion(bool value) => _update(
    _reducedMotionKey,
    value,
    (v) => state.value!.copyWith(reducedMotion: v),
  );

  /// Persists the sound preference. No sound is actually played yet in v1
  /// (see contract section 10 / KNOWN_LIMITATIONS.md) — this only stores
  /// the user's choice so it is honored once audio feedback is wired in.
  Future<void> setSoundEnabled(bool value) =>
      _update(_soundKey, value, (v) => state.value!.copyWith(soundEnabled: v));

  /// Persists the haptics preference. No haptic feedback is actually
  /// triggered yet in v1 — this only stores the user's choice.
  Future<void> setHapticsEnabled(bool value) => _update(
    _hapticsKey,
    value,
    (v) => state.value!.copyWith(hapticsEnabled: v),
  );

  Future<bool> purchaseRemoveAds() async {
    final purchased = await ref
        .read(purchaseServiceProvider)
        .purchase(removeAdsEntitlement);
    ref.invalidateSelf();
    await future;
    return purchased;
  }

  /// Returns the number of entitlements restored, for UI feedback.
  Future<int> restorePurchases() async {
    final restored = await ref.read(purchaseServiceProvider).restore();
    ref.invalidateSelf();
    await future;
    return restored.length;
  }
}
