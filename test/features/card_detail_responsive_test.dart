import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/features/cards/card_details_dialog.dart';
import 'package:tarot_app/infrastructure/assets/rws_deck.dart';

void main() {
  testWidgets('Real editorial content fits a small phone at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final deck = await tester.runAsync(loadRwsDeck);
    final content = await tester.runAsync(loadEditorialContent);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [editorialContentProvider.overrideWithValue(content!)],
        child: MaterialApp(
          home: Scaffold(
            body: CardDetailsDialog(card: deck!.card('pentacles_queen')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
