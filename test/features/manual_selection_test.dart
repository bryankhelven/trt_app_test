import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'free_reading_test.dart' as support;

void main() {
  testWidgets(
    'RF-018/019 cancel picker conserves deck; choose then place stays hidden',
    (tester) async {
      final repo = support.MemoryReadings();
      await support.openReading(tester, repo);
      await tester.tap(find.byKey(const Key('deck')));
      await tester.pumpAndSettle();
      expect(find.text('Escolha com calma'), findsOneWidget);
      expect(support.current(tester).remaining, 78);
      expect(find.text('Carta 0'), findsNothing);
      await tester.ensureVisible(find.text('Cancelar'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(support.current(tester).remaining, 78);
      expect(find.byType(Dialog), findsNothing);
      await tester.tap(find.byKey(const Key('deck')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choose-2')));
      await tester.pumpAndSettle();
      expect(support.current(tester).remaining, 78);
      final destination = tester.getCenter(find.byKey(const Key('table')));
      await tester.tapAt(destination);
      await tester.pumpAndSettle();
      expect(support.current(tester).placed.single.cardId, 'card-2');
      expect(support.current(tester).placed.single.revealed, isFalse);
      expect(
        tester.getCenter(find.byKey(const Key('card-card-2'))),
        destination,
      );
    },
  );
}
