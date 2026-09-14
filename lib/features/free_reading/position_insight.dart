import 'package:flutter/material.dart';

import '../../domain/cards/tarot_card.dart';
import '../../domain/cards/editorial_content.dart';

String positionPrompt(String meaning) {
  final text = meaning.toLowerCase();
  if (text.contains('se eu decidir por sim')) {
    return 'Como este símbolo ajuda a pensar nas consequências de agir ou aceitar?';
  }
  if (text.contains('se eu decidir por não')) {
    return 'O que este símbolo sugere observar ao recusar ou não agir?';
  }
  if (text.contains('elucida')) {
    return 'Que detalhe esta carta acrescenta à posição que acompanha?';
  }
  if (text.contains('futuro')) {
    return 'Que possibilidades e atitudes esta carta convida a considerar nesse horizonte?';
  }
  if (text.contains('desafio') || text.contains('obstáculo')) {
    return 'Que dificuldade ou tensão este símbolo ajuda a reconhecer?';
  }
  if (text.contains('conselho')) {
    return 'Que atitude consciente você pode experimentar a partir desta carta?';
  }
  return 'Como o significado desta carta se relaciona com “$meaning” na sua questão?';
}

class PositionInsight extends StatelessWidget {
  const PositionInsight({
    super.key,
    required this.meaning,
    this.card,
    this.content,
  });
  final String meaning;
  final TarotCard? card;
  final EditorialContent? content;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 290),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meaning,
            style: const TextStyle(
              color: Color(0xFFD4BD87),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card?.canonicalName ?? 'Carta fechada',
            style: const TextStyle(
              fontFamily: 'ArcanumSerif',
              fontSize: 23,
              color: Color(0xFFF4E9D5),
            ),
          ),
          if (content != null) ...[
            const SizedBox(height: 6),
            Text(
              content!.keywords.join(' · '),
              style: const TextStyle(color: Color(0xFFD4BD87)),
            ),
            const SizedBox(height: 10),
            Text(
              content!.conciseMeaning,
              style: const TextStyle(color: Color(0xFFF4E9D5)),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            positionPrompt(meaning),
            style: const TextStyle(
              color: Color(0xFFE2DAEA),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
  );
}
