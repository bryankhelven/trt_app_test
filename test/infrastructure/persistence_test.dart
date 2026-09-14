import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/infrastructure/persistence/database.dart';
import 'package:tarot_app/infrastructure/persistence/reading_codec.dart';
import 'package:tarot_app/infrastructure/persistence/reading_repository.dart';
import 'package:tarot_app/application/ports/reading_repository.dart';
import 'package:tarot_app/application/services/autosave.dart';
import 'package:tarot_app/domain/readings/reading_session.dart';

import '../support/fixtures.dart';

void main() {
  test(
    'Codec preserves full state and rejects unsupported/corrupt payloads',
    () {
      final s = fixtureSession()
          .placeNext(TablePosition(.123456789, .987654321), epoch)
          .reveal('card-0', epoch)
          .annotate(
            question: 'Questão 🔒',
            notes: 'Notas\nprivadas',
            now: epoch,
          );
      final restored = ReadingCodec.decode(ReadingCodec.encode(s));
      expect(ReadingCodec.encode(restored), ReadingCodec.encode(s));
      expect(() => ReadingCodec.decode('{}'), throwsA(isA<CorruptReading>()));
      expect(
        () => ReadingCodec.decode(
          ReadingCodec.encode(
            s,
          ).replaceFirst('"persistenceVersion":1', '"persistenceVersion":99'),
        ),
        throwsA(isA<CorruptReading>()),
      );
      expect(
        () => ReadingCodec.decode(
          ReadingCodec.encode(s).replaceFirst(
            '"revealed":true',
            '"revealed":true,"isReversed":true',
          ),
        ),
        throwsA(isA<CorruptReading>()),
      );
    },
  );
  test('Given saved reading, when process storage reopens, then exact state restores', () async {
    final dir = await Directory.systemTemp.createTemp('tarot-db-test-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/test.sqlite');
    final db = AppDatabase(NativeDatabase(file));
    final repo = SqlReadingRepository(db);
    final s = fixtureSession()
        .placeNext(TablePosition(.2, .3), epoch)
        .annotate(question: 'private', notes: 'local', now: epoch);
    await repo.save(s);
    await db.close();
    final nextDb = AppDatabase(NativeDatabase(file));
    addTearDown(nextDb.close);
    final next = SqlReadingRepository(nextDb);
    expect(ReadingCodec.encode((await next.active())!), ReadingCodec.encode(s));
    expect((await next.list()).length, 1);
    await next.save(s.reveal('card-0', epoch));
    expect((await next.read(s.readingId))!.placed.single.revealed, isTrue);
    await next.delete(s.readingId);
    expect(await next.active(), isNull);
    expect(await next.list(), isEmpty);
  });
  test('Schema 1 migrates to 3 preserving payload and selecting last active as FREE', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE readings (id TEXT NOT NULL PRIMARY KEY, payload TEXT NOT NULL, updated_at INTEGER NOT NULL)',
          );
          raw.execute('INSERT INTO readings VALUES (?, ?, ?)', [
            'reading-1',
            ReadingCodec.encode(fixtureSession()),
            epoch.millisecondsSinceEpoch,
          ]);
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(db.close);
    final repo = SqlReadingRepository(db);
    expect(
      ReadingCodec.encode((await repo.active())!),
      ReadingCodec.encode(fixtureSession()),
    );
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 4);
  });
  test(
    'Schema 2 migrates to 3 renaming the single active key to FREE',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(
              'CREATE TABLE readings (id TEXT NOT NULL PRIMARY KEY, payload TEXT NOT NULL, updated_at INTEGER NOT NULL)',
            );
            raw.execute(
              'CREATE TABLE active_readings (id TEXT NOT NULL PRIMARY KEY, reading_id TEXT NOT NULL REFERENCES readings(id))',
            );
            raw.execute('INSERT INTO readings VALUES (?, ?, ?)', [
              'reading-1',
              ReadingCodec.encode(fixtureSession()),
              epoch.millisecondsSinceEpoch,
            ]);
            raw.execute(
              "INSERT INTO active_readings VALUES ('active', 'reading-1')",
            );
            raw.execute('PRAGMA user_version = 2');
          },
        ),
      );
      addTearDown(db.close);
      final repo = SqlReadingRepository(db);
      expect(
        ReadingCodec.encode((await repo.active(mode: 'FREE'))!),
        ReadingCodec.encode(fixtureSession()),
      );
    },
  );
  test('Corrupt row reports typed failure without deleting or logging private payload', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SqlReadingRepository(db);
    await repo.save(fixtureSession());
    await db.customStatement(
      "UPDATE readings SET payload = 'private broken text'",
    );
    await expectLater(repo.active(), throwsA(isA<CorruptReading>()));
    expect(
      (await db.customSelect('SELECT payload FROM readings').getSingle())
          .data['payload'],
      'private broken text',
    );
    expect(CorruptReading().toString(), isNot(contains('private')));
  });
  test(
    'Autosave serializes snapshots and recovers after write failure',
    () async {
      final repo = ControlledRepository();
      final save = Autosave(repo);
      final s = fixtureSession();
      final first = save.enqueue(s);
      final second = save.enqueue(s.placeNext(TablePosition(.5, .5), epoch));
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, 1);
      repo.gates.first.complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, 2);
      final failure = expectLater(second, throwsStateError);
      repo.gates.last.completeError(StateError('disk unavailable'));
      await failure;
      final third = save.enqueue(s);
      await Future<void>.delayed(Duration.zero);
      repo.gates.last.complete();
      await third;
      await save.flush();
      expect(repo.calls, 3);
    },
  );
}

class ControlledRepository implements ReadingRepository {
  final gates = <Completer<void>>[];
  int get calls => gates.length;
  @override
  Future<void> save(ReadingSession session) {
    final c = Completer<void>();
    gates.add(c);
    return c.future;
  }

  @override
  Future<ReadingSession?> active({String mode = 'FREE'}) async => null;
  @override
  Future<ReadingSession?> read(String id) async => null;
  @override
  Future<List<ReadingSession>> list() async => [];
  @override
  Future<void> delete(String id) async {}
}
