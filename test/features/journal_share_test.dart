import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/app/app.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';
import 'package:tarot_app/features/settings/reading_share.dart';
import 'package:tarot_app/infrastructure/persistence/reading_codec.dart';

import '../support/fixtures.dart';
import 'journal_test.dart' show MemoryReadings;

void main() {
  test('JSON excludes private text by default and preserves it on opt-in', () {
    final session = fixtureSession().annotate(
      question: 'segredo q',
      notes: 'segredo n',
      now: epoch,
    );
    expect(buildReadingJsonExport(session), isNot(contains('segredo')));
    expect(
      buildReadingJsonExport(session, includePrivateNotes: true),
      contains('segredo q'),
    );
  });
  group('buildReadingShareText', () {
    test('omits question and notes by default (explicit opt-in required)', () {
      final session = fixtureSession()
          .placeNext(TablePosition(.2, .3), epoch)
          .reveal('card-0', epoch)
          .annotate(
            question: 'Como está meu ano?',
            notes: 'Privado',
            now: epoch,
          );

      final text = buildReadingShareText(session, fixtureDeck());

      expect(text, contains('Tiragem Livre'));
      expect(text, contains('Fixture 0'));
      expect(text, isNot(contains('Como está meu ano?')));
      expect(text, isNot(contains('Privado')));
      expect(text, contains('Leitura local'));
    });

    test('includes question and notes only when explicitly requested', () {
      final session = fixtureSession()
          .placeNext(TablePosition(.2, .3), epoch)
          .reveal('card-0', epoch)
          .annotate(
            question: 'Como está meu ano?',
            notes: 'Privado',
            now: epoch,
          );

      final text = buildReadingShareText(
        session,
        fixtureDeck(),
        includePrivateNotes: true,
      );

      expect(text, contains('Pergunta: Como está meu ano?'));
      expect(text, contains('Notas: Privado'));
    });

    test(
      'unrevealed cards show as "Carta fechada", never the canonical name',
      () {
        final session = fixtureSession().placeNext(
          TablePosition(.2, .3),
          epoch,
        );
        final text = buildReadingShareText(session, fixtureDeck());
        expect(text, contains('Carta fechada'));
        expect(text, isNot(contains('Fixture 0')));
      },
    );
  });

  test('buildReadingJsonExport matches ReadingCodec.encode exactly', () {
    final session = fixtureSession()
        .placeNext(TablePosition(.2, .3), epoch)
        .reveal('card-0', epoch);
    expect(
      buildReadingJsonExport(session, includePrivateNotes: true),
      ReadingCodec.encode(session),
    );
  });

  testWidgets(
    'Tapping Compartilhar and Exportar JSON on the journal detail screen '
    'never throws, even though the OS share sheet is unavailable in tests',
    (tester) async {
      // Mock the platform clipboard channel: real widget-test runs don't
      // have a system clipboard, so `Clipboard.setData` would otherwise
      // throw a MissingPluginException.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') return null;
            return null;
          });
      final repo = MemoryReadings();
      final reading = fixtureSession()
          .placeNext(TablePosition(.2, .3), epoch)
          .reveal('card-0', epoch)
          .annotate(question: 'Como está meu ano?', notes: 'Nota', now: epoch);
      await repo.save(reading);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingRepositoryProvider.overrideWithValue(repo),
            deckProvider.overrideWithValue(fixtureDeck()),
          ],
          child: const TarotApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Diário de leituras'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diário de leituras'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('journal-item-${reading.readingId}')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('journal-share-button')));
      await tester.pumpAndSettle();
      // The confirmation dialog asks whether to include private text;
      // choose "only the cards" to exercise the default (excluded) path.
      await tester.tap(find.text('Só as cartas'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('journal-export-json-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sem pergunta e notas'));
      await tester.pumpAndSettle();
      expect(
        find.text('JSON da leitura copiado para a área de transferência.'),
        findsOneWidget,
      );
    },
  );
}
