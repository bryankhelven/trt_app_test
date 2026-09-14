import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/app/app.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/features/library/library_screen.dart';

import '../support/fixtures.dart';

/// Grid item count is read off the built [GridView]'s delegate rather than
/// counting rendered widgets: with 78 cards the grid is far taller than the
/// test viewport, so `GridView.builder` only builds items near it — reading
/// `childCount` is the reliable way to assert "how many cards are in the
/// filtered set" without depending on scroll position.
int _gridChildCount(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byKey(const Key('library-grid')));
  return (grid.childrenDelegate as SliverChildBuilderDelegate).childCount!;
}

Future<void> _openLibrary(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deckProvider.overrideWithValue(fixtureDeck()),
        editorialContentProvider.overrideWithValue(fixtureEditorialContent()),
      ],
      child: const TarotApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Biblioteca de cartas'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Biblioteca de cartas'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home exposes a Biblioteca de cartas entry that opens the '
      'library with all 78 cards', (tester) async {
    await _openLibrary(tester);
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(_gridChildCount(tester), 78);
  });

  testWidgets(
    'Search filters by keyword, case/accent-insensitively, across the '
    'full set',
    (tester) async {
      await _openLibrary(tester);

      // Unique keyword only on card-30 ("Fixture 30"); uppercase exercises
      // case-insensitivity.
      await tester.enterText(
        find.byKey(const Key('library-search')),
        'CHAVE-ESPECIAL',
      );
      await tester.pumpAndSettle();
      expect(_gridChildCount(tester), 1);
      expect(find.text('Fixture 30'), findsWidgets);

      // Accent/case-insensitive name search.
      await tester.enterText(
        find.byKey(const Key('library-search')),
        'fixture 30',
      );
      await tester.pumpAndSettle();
      expect(_gridChildCount(tester), 1);
      expect(find.text('Fixture 30'), findsWidgets);

      // Clearing the search restores the full set.
      await tester.enterText(find.byKey(const Key('library-search')), '');
      await tester.pumpAndSettle();
      expect(_gridChildCount(tester), 78);
    },
  );

  testWidgets('Category chip filters to only that arcana/suit', (tester) async {
    await _openLibrary(tester);

    await tester.tap(find.byKey(const Key('library-category-wands')));
    await tester.pumpAndSettle();
    expect(_gridChildCount(tester), 14);
    expect(find.text('Fixture 22'), findsWidgets);
    expect(find.text('Fixture 0'), findsNothing);

    await tester.tap(find.byKey(const Key('library-category-major')));
    await tester.pumpAndSettle();
    expect(_gridChildCount(tester), 22);

    await tester.tap(find.byKey(const Key('library-category-all')));
    await tester.pumpAndSettle();
    expect(_gridChildCount(tester), 78);
  });

  testWidgets('Tapping a card opens its detail page with the correct content', (
    tester,
  ) async {
    await _openLibrary(tester);

    await tester.tap(find.byKey(const Key('library-card-card-0')));
    await tester.pumpAndSettle();

    expect(find.text('Fixture 0'), findsWidgets);
    expect(find.text('tema-0'), findsOneWidget);
    expect(find.text('Significado conciso 0'), findsOneWidget);
    expect(find.text('Significado estendido 0'), findsOneWidget);
    expect(find.text('Simbolismo'), findsOneWidget);
    expect(find.text('Simbolismo 0'), findsOneWidget);
    // card-0 is even -> has an element; index 0 % 3 == 0 -> has astrology.
    expect(find.text('Elemento: Fogo'), findsOneWidget);
    expect(find.text('Astrologia: Marte'), findsOneWidget);
  });

  testWidgets(
    'Detail metadata that is null in EditorialContent is omitted cleanly '
    '(no N/A placeholder)',
    (tester) async {
      await _openLibrary(tester);

      // card-1: odd -> no element; 1 % 3 != 0 -> no astrology.
      await tester.tap(find.byKey(const Key('library-card-card-1')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Elemento'), findsNothing);
      expect(find.textContaining('Astrologia'), findsNothing);
      expect(find.textContaining('N/A'), findsNothing);
    },
  );

  testWidgets(
    'Previous/Next walk the order the user arrived from and disable at '
    'the ends (documented choice: disable, not wrap)',
    (tester) async {
      await _openLibrary(tester);

      await tester.tap(find.byKey(const Key('library-card-card-0')));
      await tester.pumpAndSettle();
      expect(find.text('Fixture 0'), findsWidgets);

      final previous = find.byKey(const Key('library-detail-previous'));
      final next = find.byKey(const Key('library-detail-next'));
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();

      // First card in full-deck order: Previous disabled, Next enabled.
      expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(next).onPressed, isNotNull);

      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Fixture 1'), findsWidgets);
      await tester.ensureVisible(previous);
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(previous).onPressed, isNotNull);

      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('Fixture 0'), findsWidgets);
      await tester.ensureVisible(previous);
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
    },
  );

  testWidgets(
    'No reversed-card text or UI exists anywhere in the library feature',
    (tester) async {
      await _openLibrary(tester);
      expect(find.textContaining('invertid', findRichText: true), findsNothing);
      expect(find.textContaining('Invertid', findRichText: true), findsNothing);
      expect(find.textContaining('reversa', findRichText: true), findsNothing);
      expect(find.textContaining('Reversa', findRichText: true), findsNothing);

      await tester.tap(find.byKey(const Key('library-card-card-0')));
      await tester.pumpAndSettle();
      expect(find.textContaining('invertid', findRichText: true), findsNothing);
      expect(find.textContaining('reversa', findRichText: true), findsNothing);
    },
  );
}
