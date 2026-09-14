import 'spread_definition.dart';
import '../cards/tarot_card.dart';

/// One selectable reading mode in the home/mode-selection screen.
/// `spread == null` represents Tiragem Livre (Free Reading): unlimited
/// arbitrary placement until the deck is exhausted.
class ReadingMode {
  const ReadingMode({
    required this.id,
    required this.name,
    required this.description,
    required this.cardCountLabel,
    this.spread,
  });
  final String id, name, description, cardCountLabel;
  final SpreadDefinition? spread;
}

SpreadSlot _slot(String id, double x, double y, String meaning) =>
    SpreadSlot(slotId: id, position: TablePosition(x, y), meaningKey: meaning);

/// Data-driven catalog of the v1 predefined spreads. Adding a spread means
/// adding validated slot data here, never changing the reading engine.
class SpreadCatalog {
  SpreadCatalog._();

  static final cartaUnica = SpreadDefinition(
    spreadId: 'CARTA_UNICA',
    nameKey: 'Carta Única',
    descriptionKey: 'Uma carta para um foco simples e direto.',
    requiredCardCount: 1,
    slots: [_slot('c1', .5, .5, 'A carta')],
  );

  static final passadoPresenteFuturo = SpreadDefinition(
    spreadId: 'PASSADO_PRESENTE_FUTURO',
    nameKey: 'Passado / Presente / Futuro',
    descriptionKey: 'Três cartas para ler a linha do tempo de uma questão.',
    requiredCardCount: 3,
    slots: [
      _slot('passado', .2, .5, 'Passado'),
      _slot('presente', .5, .5, 'Presente'),
      _slot('futuro', .8, .5, 'Futuro'),
    ],
  );

  static final situacaoObstaculoConselho = SpreadDefinition(
    spreadId: 'SITUACAO_OBSTACULO_CONSELHO',
    nameKey: 'Situação / Obstáculo / Conselho',
    descriptionKey: 'Três cartas para entender e agir sobre uma questão.',
    requiredCardCount: 3,
    slots: [
      _slot('situacao', .2, .5, 'Situação'),
      _slot('obstaculo', .5, .5, 'Obstáculo'),
      _slot('conselho', .8, .5, 'Conselho'),
    ],
  );

  static final relacao = SpreadDefinition(
    spreadId: 'RELACAO',
    nameKey: 'Relação',
    descriptionKey:
        'Cinco cartas para observar uma relação entre duas pessoas.',
    requiredCardCount: 5,
    slots: [
      _slot('voce', .18, .65, 'Você'),
      _slot('outro', .82, .65, 'A outra pessoa'),
      _slot('vinculo', .5, .35, 'O vínculo entre vocês'),
      _slot('desafio', .5, .65, 'Desafio'),
      _slot('caminho', .5, .9, 'Caminho possível'),
    ],
  );

  static final ferradura = SpreadDefinition(
    spreadId: 'FERRADURA',
    nameKey: 'Ferradura',
    descriptionKey: 'Sete cartas em arco para uma visão ampla da questão.',
    requiredCardCount: 7,
    slots: [
      _slot('passado', .08, .78, 'Passado'),
      _slot('presente', .22, .5, 'Presente'),
      _slot('futuro_proximo', .36, .28, 'Futuro próximo'),
      _slot('voce', .5, .18, 'Você'),
      _slot('influencias', .64, .28, 'Influências externas'),
      _slot('obstaculos', .78, .5, 'Obstáculos'),
      _slot('resultado', .92, .78, 'Resultado provável'),
    ],
  );

  static final cruzCeltica = SpreadDefinition(
    spreadId: 'CRUZ_CELTICA',
    nameKey: 'Cruz Celta',
    descriptionKey: 'Dez cartas para a leitura mais completa e tradicional.',
    requiredCardCount: 10,
    slots: [
      _slot('situacao', .36, .46, 'Situação presente'),
      _slot('desafio', .36, .53, 'Desafio imediato'),
      _slot('fundamento', .36, .84, 'Fundamento / raiz'),
      _slot('passado_recente', .10, .50, 'Passado recente'),
      _slot('coroa', .36, .14, 'Meta / coroa'),
      _slot('futuro_proximo', .62, .50, 'Futuro próximo'),
      _slot('voce_mesmo', .88, .86, 'Como você se vê'),
      _slot('ambiente', .88, .62, 'Ambiente / outros'),
      _slot('esperancas_temores', .88, .38, 'Esperanças e temores'),
      _slot('resultado', .88, .14, 'Resultado'),
    ],
  );

  static final seSimSeNao = SpreadDefinition(
    spreadId: 'SE_SIM_SE_NAO',
    nameKey: 'Se sim / Se não',
    descriptionKey:
        'Dois caminhos: o que pode acontecer ao fazer ou não fazer.',
    requiredCardCount: 2,
    slots: [
      _slot('sim', .28, .5, 'Se eu decidir por sim'),
      _slot('nao', .72, .5, 'Se eu decidir por não'),
    ],
  );
  static final quatroElementos = SpreadDefinition(
    spreadId: 'QUATRO_ELEMENTOS',
    nameKey: 'Quatro elementos',
    descriptionKey:
        'Fogo: ação. Água: emoções. Ar: pensamento. Terra: concretização.',
    requiredCardCount: 4,
    slots: [
      _slot('fogo', .5, .16, 'Fogo · ação'),
      _slot('agua', .2, .5, 'Água · emoções'),
      _slot('ar', .8, .5, 'Ar · pensamento'),
      _slot('terra', .5, .84, 'Terra · concretização'),
    ],
  );
  static final cruzHermetica = SpreadDefinition(
    spreadId: 'CRUZ_HERMETICA',
    nameKey: 'Cruz Hermética',
    descriptionKey:
        'Onze cartas: a questão, seus desdobramentos e um conselho final.',
    requiredCardCount: 11,
    slots: [
      _slot('questao', .5, .42, 'Questão'),
      _slot('implica', .5, .58, 'No que implica'),
      _slot('proximo', .5, .08, 'Futuro próximo'),
      _slot(
        'elucida_proximo',
        .5,
        .25,
        'O que expande ou elucida o futuro próximo',
      ),
      _slot('distante', .5, .75, 'Futuro distante'),
      _slot(
        'elucida_distante',
        .5,
        .92,
        'O que expande ou elucida o futuro distante',
      ),
      _slot('desconhecido', .15, .42, 'O desconhecido'),
      _slot(
        'elucida_desconhecido',
        .15,
        .58,
        'O que expande ou elucida o desconhecido',
      ),
      _slot('conhecido', .85, .42, 'O conhecido'),
      _slot(
        'elucida_conhecido',
        .85,
        .58,
        'O que expande ou elucida o conhecido',
      ),
      _slot('conselho_final', .85, .92, 'Conselho final'),
    ],
  );

  static SpreadDefinition withPairs(SpreadDefinition base) => SpreadDefinition(
    spreadId: base.spreadId,
    nameKey: base.nameKey,
    descriptionKey: base.descriptionKey,
    requiredCardCount: base.slots.length * 2,
    slots: [
      for (final slot in base.slots)
        for (final type in ArcanaType.values)
          SpreadSlot(
            slotId: '${slot.slotId}:${type.name}',
            position: slot.position,
            meaningKey:
                '${slot.meaningKey} · ${type == ArcanaType.major ? 'Maior' : 'Menor'}',
            requiredArcana: type,
          ),
    ],
  );

  static const tiragemLivre = ReadingMode(
    id: 'FREE',
    name: 'Tiragem Livre',
    description: 'Sem limite de cartas, posicione livremente sobre a mesa.',
    cardCountLabel: 'Livre',
  );

  static List<ReadingMode> get modes => [
    tiragemLivre,
    for (final spread in [seSimSeNao, quatroElementos, cruzHermetica])
      ReadingMode(
        id: spread.spreadId,
        name: spread.nameKey,
        description: spread.descriptionKey,
        cardCountLabel: '${spread.requiredCardCount} cartas',
        spread: spread,
      ),
    ReadingMode(
      id: cartaUnica.spreadId,
      name: cartaUnica.nameKey,
      description: cartaUnica.descriptionKey,
      cardCountLabel: '1 carta',
      spread: cartaUnica,
    ),
    ReadingMode(
      id: passadoPresenteFuturo.spreadId,
      name: passadoPresenteFuturo.nameKey,
      description: passadoPresenteFuturo.descriptionKey,
      cardCountLabel: '3 cartas',
      spread: passadoPresenteFuturo,
    ),
    ReadingMode(
      id: situacaoObstaculoConselho.spreadId,
      name: situacaoObstaculoConselho.nameKey,
      description: situacaoObstaculoConselho.descriptionKey,
      cardCountLabel: '3 cartas',
      spread: situacaoObstaculoConselho,
    ),
    ReadingMode(
      id: relacao.spreadId,
      name: relacao.nameKey,
      description: relacao.descriptionKey,
      cardCountLabel: '5 cartas',
      spread: relacao,
    ),
    ReadingMode(
      id: ferradura.spreadId,
      name: ferradura.nameKey,
      description: ferradura.descriptionKey,
      cardCountLabel: '7 cartas',
      spread: ferradura,
    ),
    ReadingMode(
      id: cruzCeltica.spreadId,
      name: cruzCeltica.nameKey,
      description: cruzCeltica.descriptionKey,
      cardCountLabel: '10 cartas',
      spread: cruzCeltica,
    ),
  ];

  static ReadingMode byId(String id) =>
      modes.firstWhere((m) => m.id == id, orElse: () => tiragemLivre);
}
