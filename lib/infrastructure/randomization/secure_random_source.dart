import 'dart:math';

import '../../domain/randomization/shuffle.dart';

final class SecureRandomSource implements RandomSource {
  final Random _random = Random.secure();
  @override
  int nextInt(int maxExclusive) => _random.nextInt(maxExclusive);
}
