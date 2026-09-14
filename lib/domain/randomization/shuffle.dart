abstract interface class RandomSource {
  /// Uniform integer in [0, maxExclusive).
  int nextInt(int maxExclusive);
}

List<T> shuffle<T>(Iterable<T> input, RandomSource source) {
  final result = input.toList();
  for (var i = result.length - 1; i > 0; i--) {
    final j = source.nextInt(i + 1);
    if (j < 0 || j > i) throw StateError('RandomSource violated its bounds');
    final temp = result[i];
    result[i] = result[j];
    result[j] = temp;
  }
  return List.unmodifiable(result);
}

List<T> cut<T>(List<T> input, int index) {
  RangeError.checkValueInInterval(index, 0, input.length, 'index');
  return List.unmodifiable([...input.skip(index), ...input.take(index)]);
}
