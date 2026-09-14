import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'infrastructure/assets/rws_deck.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Cormorant Garamond',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final deck = await loadRwsDeck();
  final content = await loadEditorialContent();
  runApp(
    ProviderScope(
      overrides: [
        deckProvider.overrideWithValue(deck),
        editorialContentProvider.overrideWithValue(content),
      ],
      child: const TarotApp(),
    ),
  );
}
