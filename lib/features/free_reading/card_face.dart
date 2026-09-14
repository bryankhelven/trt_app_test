import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Renders a card: bundled RWS artwork when [artworkAssetId] is known and
/// [faceUp] is true, the shared card back otherwise, falling back to the
/// original procedural placeholder when no artwork asset is bundled (e.g.
/// development/test decks).
class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.width,
    this.name,
    this.number,
    this.artworkAssetId,
    this.faceUp = false,
  });
  final double width;
  final String? name;
  final int? number;
  final String? artworkAssetId;
  final bool faceUp;

  bool get _hasArtwork => artworkAssetId?.startsWith('assets/') ?? false;

  @override
  Widget build(BuildContext context) {
    final height = width * 5 / 3;
    if (!faceUp) {
      return SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: ArcanumCardBack()),
      );
    }
    if (_hasArtwork) {
      final asset = artworkAssetId!;
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCAB78A), width: 1.5),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                _placeholder(width, height),
          ),
        ),
      );
    }
    return _placeholder(width, height);
  }

  Widget _placeholder(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFF0E7D2),
      border: Border.all(color: const Color(0xFFCAB78A)),
      borderRadius: BorderRadius.circular(5),
    ),
    padding: const EdgeInsets.all(3),
    child: ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 54,
          child: Text(
            '$number\n${name ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF243C34), fontSize: 11),
          ),
        ),
      ),
    ),
  );
}

/// Original vector card back: scales without bitmap blur in every layout.
class ArcanumCardBack extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final round = RRect.fromRectAndRadius(
      rect.deflate(.8),
      Radius.circular(size.width * .065),
    );
    canvas.drawRRect(
      round,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17142D), Color(0xFF432646), Color(0xFF17142D)],
        ).createShader(rect),
    );
    final line = Paint()
      ..color = const Color(0xFFCAB78A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, size.width * .012);
    canvas.drawRRect(round, line);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(size.width * .07),
        Radius.circular(size.width * .04),
      ),
      line..color = const Color(0x99CAB78A),
    );
    final center = rect.center;
    canvas.drawCircle(center, size.width * .31, line);
    canvas.drawCircle(
      center,
      size.width * .25,
      line..color = const Color(0x55CAB78A),
    );
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 - math.pi / 2;
      final r = size.width * (i.isEven ? .28 : .07);
      final p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(star..close(), Paint()..color = const Color(0xFFD1BD8F));
    for (final y in [.18, .82]) {
      final c = Offset(size.width * .5, size.height * y);
      canvas.drawCircle(
        c,
        size.width * .08,
        line..color = const Color(0xAACAB78A),
      );
      canvas.drawCircle(
        c + Offset(size.width * .045, -size.width * .018),
        size.width * .072,
        Paint()..color = const Color(0xFF2B1D38),
      );
    }
    for (var i = 0; i < 12; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (.17 + (i % 4) * .22),
          size.height * (.3 + (i ~/ 4) * .2),
        ),
        size.width * .008,
        Paint()..color = const Color(0x88E4D2A1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
