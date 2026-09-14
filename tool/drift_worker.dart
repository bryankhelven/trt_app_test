import 'package:drift/wasm.dart';

// Compile with the same locked Drift/SQLite versions as the application.
void main() => WasmDatabase.workerMainForOpen();
