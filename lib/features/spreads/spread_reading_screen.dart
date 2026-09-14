import 'package:flutter/material.dart';

import '../free_reading/free_reading_screen.dart';

/// Every spread uses the same manual table and domain engine.
class SpreadReadingScreen extends StatelessWidget {
  const SpreadReadingScreen({super.key, required this.modeId});
  final String modeId;
  @override
  Widget build(BuildContext context) =>
      FreeReadingScreen(key: ValueKey(modeId), modeId: modeId);
}
