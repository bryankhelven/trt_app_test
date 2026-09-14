import 'dart:io';

import 'package:tarot_app/domain/readings/reading_session.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/domain/randomization/shuffle.dart';
import 'package:tarot_app/infrastructure/randomization/secure_random_source.dart';

import '../support/fixtures.dart';

class SequenceRandom implements RandomSource {
  SequenceRandom(this.values);
  final List<int> values;
  final bounds = <int>[];
  int i = 0;
  @override
  int nextInt(int max) {
    bounds.add(max);
    return values[i++];
  }
}

void main() {
  test('AC-RNG-001 Fisher-Yates uses shrinking exclusive upper bounds', () {
    final source = SequenceRandom([0, 1, 0]);
    final input = ['a', 'b', 'c', 'd'];
    expect(shuffle(input, source), ['c', 'd', 'b', 'a']);
    expect(source.bounds, [4, 3, 2]);
    expect(input, ['a', 'b', 'c', 'd']);
  });
  test(
    'All bounded choice combinations on 3 cards yield 6 distinct permutations',
    () {
      final permutations = <String>{};
      for (var a = 0; a < 3; a++) {
        for (var b = 0; b < 2; b++) {
          permutations.add(shuffle([0, 1, 2], SequenceRandom([a, b])).join());
        }
      }
      expect(permutations.length, 6);
    },
  );
  test(
    '78-card permutations conserve all identities and exhaustion is explicit',
    () {
      for (var offset = 0; offset < 78; offset++) {
        final source = SequenceRandom([
          for (var n = 78; n > 1; n--) offset % n,
        ]);
        final result = shuffle(fixtureDeck().cardIds, source);
        expect(result.toSet(), fixtureDeck().cardIds.toSet());
        expect(result.length, 78);
        var s = fixtureSession().reorderRemaining(result, epoch);
        for (var i = 0; i < 78; i++) {
          s = s.placeNext(TablePosition(.5, .5), epoch);
        }
        expect(s.placed.map((c) => c.cardId), result);
        expect(
          () => s.placeNext(TablePosition(.5, .5), epoch),
          throwsStateError,
        );
      }
    },
  );
  test(
    'Bad injected entropy is rejected; trivial shuffles need no entropy',
    () {
      expect(() => shuffle([1, 2], SequenceRandom([2])), throwsStateError);
      expect(() => shuffle([1, 2], SequenceRandom([-1])), throwsStateError);
      expect(shuffle<int>([], SequenceRandom([])), isEmpty);
      expect(shuffle([1], SequenceRandom([])), [1]);
    },
  );
  test('Explicit cuts preserve order and already drawn prefix', () {
    expect(cut([0, 1, 2, 3], 2), [2, 3, 0, 1]);
    expect(cut([0, 1], 0), [0, 1]);
    expect(cut([0, 1], 2), [0, 1]);
    expect(() => cut([0, 1], 3), throwsRangeError);
    final s = fixtureSession().placeNext(TablePosition(.5, .5), epoch);
    final next = s.reorderRemaining(
      cut(s.drawOrder.skip(1).toList(), 4),
      epoch,
    );
    expect(next.placed.single.cardId, 'card-0');
    expect(next.drawOrder.first, 'card-0');
    expect(next.drawOrder[1], 'card-5');
  });
  test('Production adapter uses only Random.secure and bounded nextInt', () {
    final text = File(
      'lib/infrastructure/randomization/secure_random_source.dart',
    ).readAsStringSync();
    expect(text, contains('Random.secure()'));
    expect(RegExp(r'Random\s*\(').hasMatch(text), isFalse);
    final source = SecureRandomSource();
    for (var i = 0; i < 100; i++) {
      expect(source.nextInt(78), inInclusiveRange(0, 77));
    }
  });
}
