import 'dart:convert';

import '../../application/ports/reading_repository.dart';
import '../../domain/readings/reading_session.dart';
import '../../domain/spreads/spread_definition.dart';
import '../../domain/cards/tarot_card.dart';

class ReadingCodec {
  static String encode(ReadingSession s) => jsonEncode({
    'persistenceVersion': s.persistenceVersion,
    'readingId': s.readingId,
    'createdAt': s.createdAt.toIso8601String(),
    'updatedAt': s.updatedAt.toIso8601String(),
    'deckId': s.deckId,
    'deckVersion': s.deckVersion,
    'contentVersion': s.contentVersion,
    'drawOrder': s.drawOrder,
    'question': s.question,
    'notes': s.notes,
    'spread': s.spread == null
        ? null
        : {
            'spreadId': s.spread!.spreadId,
            'nameKey': s.spread!.nameKey,
            'descriptionKey': s.spread!.descriptionKey,
            'requiredCardCount': s.spread!.requiredCardCount,
            'slots': [
              for (final slot in s.spread!.slots)
                {
                  'slotId': slot.slotId,
                  'x': slot.position.x,
                  'y': slot.position.y,
                  'meaningKey': slot.meaningKey,
                  if (slot.requiredArcana != null)
                    'requiredArcana': slot.requiredArcana!.name,
                },
            ],
          },
    'placed': [
      for (final c in s.placed)
        {
          'cardId': c.cardId,
          'drawIndex': c.drawIndex,
          'x': c.position.x,
          'y': c.position.y,
          'revealed': c.revealed,
          'zIndex': c.zIndex,
          'slotId': c.slotId,
          if (c.complementOf != null) 'complementOf': c.complementOf,
          if (c.associationOrder != null)
            'associationOrder': c.associationOrder,
        },
    ],
  });
  static Map<String, dynamic> _object(dynamic value, Set<String> keys) {
    final map = value as Map<String, dynamic>;
    if (map.length != keys.length || !keys.containsAll(map.keys)) {
      throw const FormatException();
    }
    return map;
  }

  static ReadingSession decode(String payload) {
    try {
      final s = _object(jsonDecode(payload), {
        'persistenceVersion',
        'readingId',
        'createdAt',
        'updatedAt',
        'deckId',
        'deckVersion',
        'contentVersion',
        'drawOrder',
        'question',
        'notes',
        'spread',
        'placed',
      });
      SpreadDefinition? spread;
      if (s['spread'] != null) {
        final sp = _object(s['spread'], {
          'spreadId',
          'nameKey',
          'descriptionKey',
          'requiredCardCount',
          'slots',
        });
        spread = SpreadDefinition(
          spreadId: sp['spreadId'] as String,
          nameKey: sp['nameKey'] as String,
          descriptionKey: sp['descriptionKey'] as String,
          requiredCardCount: sp['requiredCardCount'] as int,
          slots: (sp['slots'] as List).map((value) {
            final slot = _object(value, {
              'slotId',
              'x',
              'y',
              'meaningKey',
              if ((value as Map).containsKey('requiredArcana'))
                'requiredArcana',
            });
            return SpreadSlot(
              slotId: slot['slotId'] as String,
              position: TablePosition(
                (slot['x'] as num).toDouble(),
                (slot['y'] as num).toDouble(),
              ),
              meaningKey: slot['meaningKey'] as String,
              requiredArcana: slot['requiredArcana'] == null
                  ? null
                  : ArcanaType.values.byName(slot['requiredArcana'] as String),
            );
          }),
        );
      }
      return ReadingSession(
        readingId: s['readingId'] as String,
        createdAt: DateTime.parse(s['createdAt'] as String),
        updatedAt: DateTime.parse(s['updatedAt'] as String),
        deckId: s['deckId'] as String,
        deckVersion: s['deckVersion'] as String,
        contentVersion: s['contentVersion'] as String,
        persistenceVersion: s['persistenceVersion'] as int,
        drawOrder: (s['drawOrder'] as List).cast<String>(),
        question: s['question'] as String,
        notes: s['notes'] as String,
        spread: spread,
        placed: (s['placed'] as List).map((value) {
          final c = _object(value, {
            'cardId',
            'drawIndex',
            'x',
            'y',
            'revealed',
            'zIndex',
            'slotId',
            if ((value as Map).containsKey('complementOf')) 'complementOf',
            if (value.containsKey('associationOrder')) 'associationOrder',
          });
          return PlacedCard(
            cardId: c['cardId'] as String,
            drawIndex: c['drawIndex'] as int,
            position: TablePosition(
              (c['x'] as num).toDouble(),
              (c['y'] as num).toDouble(),
            ),
            revealed: c['revealed'] as bool,
            zIndex: c['zIndex'] as int,
            slotId: c['slotId'] as String?,
            complementOf: c['complementOf'] as String?,
            associationOrder: c['associationOrder'] as int?,
          );
        }),
      );
    } on Object {
      // No payload in exception/logging: questions and notes are private.
      throw CorruptReading();
    }
  }
}
