import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/app/routing/router.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';
import 'package:tarot_app/features/free_reading/reading_controller.dart';

import 'free_reading_test.dart' as support;

void main() {
  testWidgets(
    'R2 explicitly saved table opens by id; draft exit never restores automatically',
    (tester) async {
      final repo = support.MemoryReadings();
      final c = await support.openReading(tester, repo);
      await support.draw(
        tester,
        tester.getCenter(find.byKey(const Key('table'))),
      );
      await tester.tap(find.byKey(const Key('save-reading')));
      await tester.pumpAndSettle();
      final saved = repo.saved!;
      c.read(routerProvider).go('/');
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/journal/${saved.readingId}/table');
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('card-${saved.placed.single.cardId}')),
        findsOneWidget,
      );
      expect(find.text('Tiragem salva neste dispositivo'), findsOneWidget);
      await tester.tap(find.byKey(Key('card-${saved.placed.single.cardId}')));
      await tester.pumpAndSettle();
      expect(repo.saved!.placed.single.revealed, isFalse);
      await tester.tap(find.byTooltip('Início'));
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/reading/free');
      await tester.pumpAndSettle();
      expect(support.current(tester).placed, isEmpty);
      expect(repo.saved, same(saved));
    },
  );
  testWidgets('R2 new reading prompts before discard and restores full deck', (
    tester,
  ) async {
    final c = await support.openReading(tester, support.MemoryReadings());
    await c
        .read(readingControllerProvider.notifier)
        .draw(TablePosition(.5, .5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-reading')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar esta'));
    await tester.pumpAndSettle();
    expect(support.current(tester).remaining, 77);
    await tester.tap(find.byKey(const Key('new-reading')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar e começar'));
    await tester.pumpAndSettle();
    expect(support.current(tester).remaining, 78);
    expect(support.current(tester).question, isEmpty);
    expect(support.current(tester).notes, isEmpty);
  });
}
