import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/features/free_reading/deck_picker.dart';

import '../support/fixtures.dart';

void main() {
  testWidgets(
    'R2 browse major/minor groups hides identities and chooses exact card',
    (tester) async {
      DeckChoice? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<DeckChoice>(
                    context: context,
                    builder: (_) => DeckPicker(
                      ids: fixtureDeck().cardIds.toList(),
                      deck: fixtureDeck(),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maiores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Percorrer'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 22'), findsOneWidget);
      expect(find.textContaining('Fixture'), findsNothing);
      await tester.tap(find.byTooltip('Próxima carta'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 22'), findsOneWidget);
      await tester.tap(find.text('Menores'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 56'), findsOneWidget);
      await tester.tap(find.text('Escolher esta carta'));
      await tester.pumpAndSettle();
      expect(result!.cardId, 'card-22');
    },
  );
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('R2 divide three piles, reunite selected pile first $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      DeckChoice? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<DeckChoice>(
                    context: context,
                    builder: (_) => DeckPicker(
                      ids: fixtureDeck().cardIds.toList(),
                      deck: fixtureDeck(),
                      initialMode: 2,
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('3'));
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Monte 2 · 26'));
      await tester.tap(find.text('Monte 2 · 26'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('choose-26')), findsOneWidget);
      await tester.ensureVisible(find.text('Reunir a partir deste monte'));
      await tester.tap(find.text('Reunir a partir deste monte'));
      await tester.pumpAndSettle();
      expect(result!.reordered!.first, 'card-26');
      expect(result!.reordered!.length, 78);
      expect(result!.reordered!.toSet(), fixtureDeck().cardIds.toSet());
      expect(tester.takeException(), isNull);
    });
  }
}
