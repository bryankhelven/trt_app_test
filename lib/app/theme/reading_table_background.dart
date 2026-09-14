import 'package:flutter/material.dart';

/// The shared reading-table backdrop: a subtle forest-green radial gradient
/// with a faint outline, giving the table a sense of depth without any
/// glow/neon. Used by both Free Reading and predefined-spread boards so the
/// two screens share one visual language instead of two copies of the same
/// [BoxDecoration].
class ReadingTableBackground extends StatelessWidget {
  const ReadingTableBackground({super.key, this.child});
  final Widget? child;

  static const decoration = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(-.3, -.3),
      radius: 1.2,
      colors: [Color(0xFF2D153B), Color(0xFF111126), Color(0xFF0B0B17)],
    ),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFF493957), width: .5),
    ),
  );

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: Theme.of(context).brightness == Brightness.dark
        ? decoration
        : const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFFF7EEDF), Color(0xFFE4D9C9)],
              radius: 1.3,
            ),
          ),
    child: child,
  );
}
