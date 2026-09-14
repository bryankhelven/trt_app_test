import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/features/free_reading/card_motion.dart';

void main() {
  testWidgets('R3 arrival and move interpolate; reduced motion snaps', (
    t,
  ) async {
    Widget scene(Rect destination, {bool reduced = false}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          CardTravel(
            destination: destination,
            origin: const Rect.fromLTWH(0, 0, 40, 60),
            reducedMotion: reduced,
            child: const SizedBox(key: Key('card')),
          ),
        ],
      ),
    );
    const first = Rect.fromLTWH(200, 200, 80, 130);
    await t.pumpWidget(scene(first));
    expect(t.getTopLeft(find.byKey(const Key('card'))), Offset.zero);
    await t.pump(const Duration(milliseconds: 100));
    final midway = t.getTopLeft(find.byKey(const Key('card')));
    expect(midway.dx, greaterThan(0));
    expect(midway.dx, lessThan(200));
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.byKey(const Key('card'))), first.topLeft);
    const next = Rect.fromLTWH(400, 100, 80, 130);
    await t.pumpWidget(scene(next));
    await t.pump(const Duration(milliseconds: 100));
    expect(
      t.getTopLeft(find.byKey(const Key('card'))).dx,
      inExclusiveRange(200, 400),
    );
    await t.pumpWidget(scene(first, reduced: true));
    expect(t.getTopLeft(find.byKey(const Key('card'))), first.topLeft);
    expect(t.hasRunningAnimations, isFalse);
  });
  testWidgets(
    'R3 flip shows back first, front after half turn, reduced motion immediate',
    (t) async {
      Widget scene(bool revealed, {bool reduced = false}) => Directionality(
        textDirection: TextDirection.ltr,
        child: CardTurn(
          revealed: revealed,
          reducedMotion: reduced,
          front: const Text('front'),
          back: const Text('back'),
        ),
      );
      await t.pumpWidget(scene(false));
      await t.pumpWidget(scene(true));
      expect(find.text('back'), findsOneWidget);
      expect(find.text('front'), findsNothing);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('front'), findsOneWidget);
      await t.pumpAndSettle();
      await t.pumpWidget(scene(false, reduced: true));
      expect(find.text('back'), findsOneWidget);
      expect(t.hasRunningAnimations, isFalse);
    },
  );
}
