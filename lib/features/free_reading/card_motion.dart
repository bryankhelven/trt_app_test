import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Uses the released pointer as the start of a snap, and the deck on arrival.
/// During a drag the screen renders feedback directly at the pointer.
class CardTravel extends StatefulWidget {
  const CardTravel({
    super.key,
    required this.destination,
    required this.origin,
    required this.reducedMotion,
    required this.child,
    this.releaseOrigin,
  });
  final Rect destination, origin;
  final Rect? releaseOrigin;
  final bool reducedMotion;
  final Widget child;
  @override
  State<CardTravel> createState() => _CardTravelState();
}

class _CardTravelState extends State<CardTravel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  late RectTween _path;
  Rect get _rect =>
      _path.transform(Curves.easeOutCubic.transform(_motion.value))!;
  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _path = RectTween(
      begin: widget.releaseOrigin ?? widget.origin,
      end: widget.destination,
    );
    if (widget.reducedMotion) {
      _motion.value = 1;
    } else {
      _motion.forward();
    }
  }

  @override
  void didUpdateWidget(CardTravel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destination != oldWidget.destination ||
        widget.releaseOrigin != oldWidget.releaseOrigin) {
      final start = widget.releaseOrigin != oldWidget.releaseOrigin
          ? widget.releaseOrigin ?? _rect
          : _rect;
      _path = RectTween(begin: start, end: widget.destination);
      _motion.forward(from: 0);
    }
    if (widget.reducedMotion) {
      _motion.stop();
      _motion.value = 1;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _motion,
    child: widget.child,
    builder: (_, child) => Positioned.fromRect(rect: _rect, child: child!),
  );
}

/// Face visibility changes at the edge of the flip, never before it.
class CardTurn extends StatefulWidget {
  const CardTurn({
    super.key,
    required this.revealed,
    required this.reducedMotion,
    required this.front,
    required this.back,
  });
  final bool revealed, reducedMotion;
  final Widget front, back;
  @override
  State<CardTurn> createState() => _CardTurnState();
}

class _CardTurnState extends State<CardTurn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn;
  @override
  void initState() {
    super.initState();
    _turn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: widget.revealed ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(CardTurn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion) {
      _turn.stop();
      _turn.value = widget.revealed ? 1 : 0;
    } else if (widget.revealed != oldWidget.revealed) {
      widget.revealed ? _turn.forward() : _turn.reverse();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _turn,
    builder: (_, child) {
      final progress = Curves.easeInOut.transform(_turn.value);
      final front = progress >= .5;
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0015)
          ..rotateY(math.pi * (progress - (front ? 1 : 0))),
        child: front ? widget.front : widget.back,
      );
    },
  );
}
