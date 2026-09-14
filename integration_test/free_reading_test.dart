import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tarot_app/app/app.dart';
import 'package:tarot_app/app/providers.dart';
import 'package:tarot_app/app/routing/router.dart';
import 'package:tarot_app/features/free_reading/reading_controller.dart';
import 'package:tarot_app/infrastructure/persistence/database.dart';
import 'package:tarot_app/infrastructure/persistence/reading_codec.dart';
import 'package:tarot_app/infrastructure/persistence/reading_repository.dart';

AppDatabase database() => AppDatabase(
  driftDatabase(
    name: 'arcanum_revision2_integration',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ),
);
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'R2 real storage: draft never writes; explicit save reopens exact table',
    (tester) async {
      var db = database();
      var repo = SqlReadingRepository(db);
      Future<ProviderContainer> launch() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [readingRepositoryProvider.overrideWithValue(repo)],
            child: const TarotApp(),
          ),
        );
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TarotApp)),
        );
        container.read(routerProvider).go('/reading/free');
        await tester.pumpAndSettle();
        return container;
      }

      for (final s in await repo.list()) {
        await repo.delete(s.readingId);
      }
      var c = await launch();
      final table = tester.getRect(find.byKey(const Key('table')));
      for (var i = 0; i < 3; i++) {
        final g = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('deck'))),
        );
        await g.moveTo(table.center + Offset((i - 1) * 110, 0));
        await tester.pump();
        await g.up();
        await tester.pumpAndSettle();
      }
      final session = c.read(readingControllerProvider).requireValue.session;
      expect(session.placed.length, 3);
      expect(await repo.list(), isEmpty);
      await tester.tap(find.byKey(Key('card-${session.placed.first.cardId}')));
      await tester.pumpAndSettle();
      await c
          .read(readingControllerProvider.notifier)
          .annotate('Questão privada', 'Notas locais');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-reading')));
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 100 && !c.read(readingControllerProvider).requireValue.saved;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final saved = (await repo.read(session.readingId))!;
      expect(saved.placed.first.revealed, isTrue);
      expect(saved.notes, 'Notas locais');
      final encoded = ReadingCodec.encode(saved);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await db.close();
      db = database();
      repo = SqlReadingRepository(db);
      c = await launch();
      expect(
        c.read(readingControllerProvider).requireValue.session.placed,
        isEmpty,
      );
      expect(ReadingCodec.encode((await repo.read(saved.readingId))!), encoded);
      c.read(routerProvider).go('/journal/${saved.readingId}/table');
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 100 &&
            find
                .byKey(Key('card-${saved.placed.first.cardId}'))
                .evaluate()
                .isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        find.byKey(Key('card-${saved.placed.first.cardId}')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await repo.delete(saved.readingId);
      await db.close();
    },
  );
}
