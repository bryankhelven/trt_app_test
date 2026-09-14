import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/cards/tarot_card.dart';
import '../../domain/readings/reading_session.dart';
import '../../domain/spreads/spread_definition.dart';

/// Projection changes with both viewport dimensions. Saved positions never do.
class TableGeometry {
  TableGeometry(this.size, this.spread) {
    final paired = spread?.slots.any((s) => s.requiredArcana != null) ?? false;
    final simple = (spread?.slots.length ?? 0) <= (paired ? 6 : 3);
    final landscape = size.height < 450 && size.width > size.height;
    final dense = spread?.spreadId == 'CRUZ_HERMETICA';
    final deckWidth = math
        .min(size.width * .12, size.height * .16)
        .clamp(26.0, 66.0);
    deck = Rect.fromLTWH(
      size.width - deckWidth - 14,
      12,
      deckWidth,
      deckWidth * 5 / 3,
    );
    final reserve = spread == null ? 0.0 : math.min(230.0, size.height * .28);
    staging = Rect.fromLTWH(
      16,
      size.height - reserve,
      size.width - 32,
      math.max(0, reserve - 8),
    );
    area = Rect.fromLTRB(
      16,
      landscape
          ? 36
          : dense
          ? 40
          : math.min(80.0, size.height * .20),
      landscape ? deck.left - 18 : size.width - 16,
      size.height - 24 - reserve,
    );
    final candidateWidth = spread == null
        ? math.min(size.width * .16, size.height * .25).clamp(30.0, 120.0)
        : math
              .min(
                area.width *
                    (simple ? (paired ? .09 : .18) : (paired ? .08 : .14)),
                area.height *
                    (dense
                        ? .082
                        : simple
                        ? .32
                        : (landscape ? .115 : .11)),
              )
              .clamp(8.0, 140.0);
    width = spread == null
        ? candidateWidth
        : math.min(candidateWidth, staging.height * .55);
    for (final slot in spread?.slots ?? <SpreadSlot>[]) {
      var center = Offset(
        area.left + slot.position.x * area.width,
        area.top + slot.position.y * area.height,
      );
      if (slot.requiredArcana != null) {
        center += Offset(
          (slot.requiredArcana == ArcanaType.major ? -1 : 1) * width * .57,
          0,
        );
      }
      final cross =
          spread?.spreadId == 'CRUZ_CELTICA' &&
          slot.slotId.split(':').first == 'desafio';
      turns[slot.slotId] = cross ? 1 : 0;
      cards[slot.slotId] = Rect.fromCenter(
        center: center,
        width: cross ? width * 5 / 3 : width,
        height: cross ? width : width * 5 / 3,
      );
      final rect = cards[slot.slotId]!;
      final labelWidth = paired
          ? width * 1.5
          : math.max(width * 1.5, math.min(160.0, area.width * .18));
      // The two central Celtic cards cross intentionally; their labels sit to
      // either side of the center, outside both card faces.
      if (spread?.spreadId == 'CRUZ_CELTICA' &&
          ['situacao', 'desafio'].contains(slot.slotId.split(':').first)) {
        labels[slot.slotId] = area.width < 500
            ? Rect.fromLTWH(
                rect.center.dx - labelWidth / 2,
                cross ? rect.bottom + 2 : rect.top - 26,
                labelWidth,
                24,
              )
            : Rect.fromLTWH(
                rect.center.dx +
                    (cross ? width * 1.05 : -width * 1.05 - labelWidth),
                rect.center.dy - 9,
                labelWidth,
                24,
              );
      } else {
        labels[slot.slotId] = Rect.fromLTWH(
          rect.center.dx - labelWidth / 2,
          rect.bottom + 2,
          labelWidth,
          dense ? 12 : 24,
        );
      }
    }
    // Each logical position gets its own adjacent landing area. Choose the
    // side with the least overlap; the underlying cross is never rearranged.
    for (final id
        in (spread?.slots ?? <SpreadSlot>[])
            .map((s) => ReadingSession.positionId(s.slotId))
            .toSet()) {
      final group = cards.entries
          .where((e) => ReadingSession.positionId(e.key) == id)
          .map((e) => e.value);
      final bounds = group.reduce((a, b) => a.expandToInclude(b));
      final candidates =
          [
                for (var radius = 1.4; radius <= 6; radius += .4)
                  for (var angle = 0; angle < 16; angle++)
                    bounds.center +
                        Offset(
                              math.cos(angle * math.pi / 8),
                              math.sin(angle * math.pi / 8),
                            ) *
                            (width * radius),
                Offset(bounds.right + width * .7, bounds.center.dy),
                Offset(bounds.left - width * .7, bounds.center.dy),
                Offset(bounds.center.dx, bounds.bottom + width * 1.05),
                Offset(bounds.center.dx, bounds.top - width * 1.05),
              ]
              .map(
                (c) => Rect.fromCenter(
                  center: c,
                  width: width,
                  height: width * 5 / 3,
                ),
              )
              .toList();
      double score(Rect r) {
        var result = (r.center - bounds.center).distance;
        for (final other in [...cards.values, ...complements.values]) {
          final overlap = r.inflate(3).intersect(other);
          if (!overlap.isEmpty) result += 1e7 + overlap.width * overlap.height;
        }
        for (final label in labels.values) {
          final overlap = r.intersect(label);
          if (!overlap.isEmpty) result += overlap.width * overlap.height * .2;
        }
        if (r.left < 8 ||
            r.right > size.width - 8 ||
            r.top < 30 ||
            r.bottom > staging.top - 4 ||
            r.overlaps(deck)) {
          result += 1e12;
        }
        return result;
      }

      var best = candidates.first;
      var bestScore = double.infinity;
      for (final candidate in candidates) {
        final value = score(candidate);
        if (value < bestScore) {
          best = candidate;
          bestScore = value;
        }
      }
      complements[id] = best;
    }
  }
  final Size size;
  final SpreadDefinition? spread;
  late final Rect deck, area, staging;
  final complements = <String, Rect>{};
  late final double width;
  final cards = <String, Rect>{};
  final labels = <String, Rect>{};
  final turns = <String, int>{};
  Rect cardRect(PlacedCard card, ReadingSession session) {
    if (card.slotId != null) return cards[card.slotId]!;
    if (card.complementOf == null) return freeRect(card.position);
    final anchor = complements[card.complementOf]!;
    final count = session.complementsFor(card.complementOf!).length;
    final index = session.complementNumber(card) - 1;
    final step = math.min(
      width * .38,
      math.max(0, staging.top - anchor.bottom - 4) / math.max(1, count - 1),
    );
    return anchor.shift(Offset(0, index * step));
  }

  Rect freeRect(TablePosition p) => Rect.fromLTWH(
    (p.x * size.width - width / 2).clamp(0, math.max(0, size.width - width)),
    (p.y * size.height - width * 5 / 6).clamp(
      0,
      math.max(0, size.height - width * 5 / 3),
    ),
    width,
    width * 5 / 3,
  );
}

class SpreadLines extends CustomPainter {
  SpreadLines(this.geometry);
  final TableGeometry geometry;
  @override
  void paint(Canvas canvas, Size size) {
    final id = geometry.spread?.spreadId;
    if (!['CRUZ_CELTICA', 'CRUZ_HERMETICA', 'QUATRO_ELEMENTOS'].contains(id)) {
      return;
    }
    final a = geometry.area;
    final x = id == 'CRUZ_CELTICA' ? .36 : .5;
    final paint = Paint()
      ..color = const Color(0x66CAB78A)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    Offset p(double x, double y) =>
        Offset(a.left + x * a.width, a.top + y * a.height);
    canvas.drawLine(p(x, .09), p(x, .90), paint);
    canvas.drawLine(p(.08, .5), p(id == 'CRUZ_CELTICA' ? .67 : .92, .5), paint);
    if (id == 'CRUZ_CELTICA') {
      canvas.drawOval(
        Rect.fromCenter(
          center: p(x, .5),
          width: a.width * .49,
          height: a.height * .76,
        ),
        paint..color = const Color(0x22CAB78A),
      );
      canvas.drawLine(p(.88, .1), p(.88, .9), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SpreadLines oldDelegate) =>
      oldDelegate.geometry != geometry;
}
