import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/app/app.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/app/routing/router.dart';
import 'package:tarot_app/features/free_reading/reading_controller.dart';

import '../support/fixtures.dart';

import 'package:tarot_app/domain/cards/editorial_content.dart';
import 'package:tarot_app/features/free_reading/position_insight.dart';

import 'free_reading_test.dart' as support;

void main() {
  testWidgets('R2 floating explanation never intercepts clicks on the deck', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingRepositoryProvider.overrideWithValue(support.MemoryReadings()),
          deckProvider.overrideWithValue(fixtureDeck()),
          randomProvider.overrideWithValue(support.OrderedRandom()),
          editorialContentProvider.overrideWithValue({
            'pending-0': EditorialContent(
              cardId: 'card-0',
              keywords: ['possibilidades', 'aprendizado'],
              conciseMeaning: List.filled(
                5,
                'Uma oportunidade concreta de aprendizado e reflexão pede atenção às escolhas.',
              ).join(' '),
              extendedMeaning: 'Detalhes',
              symbolism: 'Símbolos',
            ),
          }),
        ],
        child: const TarotApp(),
      ),
    );
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.byType(TarotApp)));
    c.read(routerProvider).go('/reading/spread/CRUZ_CELTICA');
    await tester.pumpAndSettle();
    final controller = c.read(
      readingControllerProviderFor('CRUZ_CELTICA').notifier,
    );
    final s = support.current(tester, 'CRUZ_CELTICA');
    final slot = s.spread!.slots[8];
    await controller.draw(slot.position, slotId: slot.slotId);
    await controller.reveal('card-0');
    await tester.pumpAndSettle();
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(
      tester.getCenter(find.byKey(const Key('card-card-0'))),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(
      tester
          .getRect(find.byType(PositionInsight))
          .contains(tester.getCenter(find.byKey(const Key('deck')))),
      isTrue,
    );
    await tester.tap(find.byKey(const Key('deck')));
    await tester.pumpAndSettle();
    expect(find.text('Escolha com calma'), findsOneWidget);
    await pointer.removePointer();
  });
  testWidgets(
    'R2 hover relates revealed card content to its position; closed cards stay private',
    (tester) async {
      final repo = support.MemoryReadings();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingRepositoryProvider.overrideWithValue(repo),
            deckProvider.overrideWithValue(fixtureDeck()),
            editorialContentProvider.overrideWithValue(
              fixtureEditorialContent(),
            ),
            randomProvider.overrideWithValue(support.OrderedRandom()),
          ],
          child: const TarotApp(),
        ),
      );
      await tester.pumpAndSettle();
      final c = ProviderScope.containerOf(
        tester.element(find.byType(TarotApp)),
      );
      c.read(routerProvider).go('/reading/spread/SE_SIM_SE_NAO');
      await tester.pumpAndSettle();
      final controller = c.read(
        readingControllerProviderFor('SE_SIM_SE_NAO').notifier,
      );
      final slot = support.current(tester, 'SE_SIM_SE_NAO').spread!.slots.first;
      await controller.draw(slot.position, slotId: slot.slotId);
      await tester.pumpAndSettle();
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: Offset.zero);
      final target = tester.getCenter(find.byKey(const Key('card-card-0')));
      await pointer.moveTo(target);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Fixture 0'), findsNothing);
      expect(find.text('Significado conciso 0'), findsNothing);
      await pointer.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('card-card-0')));
      await tester.pumpAndSettle();
      await pointer.moveTo(target);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Significado conciso 0'), findsOneWidget);
      expect(
        find.text(
          'Como este símbolo ajuda a pensar nas consequências de agir ou aceitar?',
        ),
        findsOneWidget,
      );
      await pointer.removePointer();
    },
  );
}
