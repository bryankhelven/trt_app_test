import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Domain and application preserve dependency boundaries', () {
    for (final layer in ['domain', 'application']) {
      for (final file
          in Directory('lib/$layer')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final imports = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''')
            .allMatches(file.readAsStringSync())
            .map((m) => m[1]!);
        for (final uri in imports) {
          expect(uri, isNot(contains('package:flutter')), reason: file.path);
          expect(uri, isNot(contains('infrastructure/')), reason: file.path);
          expect(uri, isNot(contains('features/')), reason: file.path);
          expect(uri, isNot(contains('package:drift')), reason: file.path);
          if (layer == 'domain') {
            expect(uri, isNot(contains('application/')), reason: file.path);
          }
        }
      }
    }
  });
  test(
    'Hard invariants: forbidden semantics and full-screen SDKs stay absent',
    () {
      final forbidden = RegExp(
        r'\b(isReversed|reversedMeaning|uprightMeaning|orientationMeaning|InterstitialAd|RewardedAd|RewardedInterstitialAd|AppOpenAd)\b',
      );
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        expect(
          forbidden.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: file.path,
        );
      }
    },
  );
}
