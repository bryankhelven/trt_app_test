import 'package:drift_flutter/drift_flutter.dart';

import 'database.dart';

AppDatabase openDatabase() => AppDatabase(
  driftDatabase(
    name: const String.fromEnvironment(
      'DATABASE_NAME',
      defaultValue: 'tarot_development_v1',
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ),
);
