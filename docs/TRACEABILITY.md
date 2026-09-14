# Rastreabilidade vigente — revisão 3

A correção explícita do usuário substitui as restrições antigas de movimentação. Critérios em `docs/spec/REVISION_3.md`.

| Critério | Implementação | Testes |
|---|---|---|
| R3-01/02 retirada escolhida, mesa livre e encaixe posterior | ReadingSession.move, ReadingController, gestos e DeckPicker sem filtro implícito | revision3_test, revision3_gestures_test |
| R3-03 título Carta X | ReadingSession.cardLabel e cabeçalho da carta | revision3_test, revision3_gestures_test |
| R3-04/05 complementos somente após aproximação de uma principal ocupada, reordenação e persistência | área de aproximação invisível, complementOf, associationOrder, ReadingCodec, diário e exportação | revision3_test, revision3_gestures_test |
| R3-06 espaço e orientação | TableGeometry.staging e destinos adjacentes sem sobrepor principais | responsive_spreads_test, revision3_gestures_test |
| R3-07 animações e acessibilidade | CardTravel, CardTurn, animação de retirada, configuração de movimento reduzido | card_motion_test |
| R3-08 preservação dos fluxos anteriores | mesma sessão temporária e salvamento explícito | suíte completa, validação web R3 |
| R3-09 atualização visível da prévia Web | ativação imediata do novo worker, detecção de controle anterior e recarga única | primeira abertura limpa na porta 8881 e validação web R3 |

Evidências desta revisão em `docs/evidence/revision3`. A revisão 2 abaixo continua válida onde não foi substituída.

---

# Rastreabilidade anterior — revisão 2

O pedido posterior do usuário prevalece sobre a elicitação e decisões herdadas em caso de conflito. Documento original preservado. Especificação da revisão: docs/spec/REVISION_2.md.

| Critério | Implementação | Evidência atual |
|---|---|---|
| R2-01/02 temporária, salvar e nova | ReadingController, SavedTableScreen, botões explícitos | revision2_test, saved_table_test, free_reading_test |
| R2-03 geometria e orientação | TableGeometry, SpreadLines, InteractiveViewer, cabeçalho compacto | responsive_spreads_test, capturas Web |
| R2-04 modos solicitados | SpreadCatalog (10 modos, Hermética 11 posições) | domain_test, elicitation_test, revision2_test |
| R2-05 maior+menor | withPairs, requiredArcana, validação antes da retirada, codec compatível | revision2_test (nove estruturas, tipos e round trip) |
| R2-06 seleção/divisão | DeckPicker distribuídas/percorrer/dividir, 2/3 montes, filtros | deck_picker_test, manual_selection_test, Web |
| R2-07 verso próprio | ArcanumCardBack CustomPainter | screenshots e fonte versionável |
| R2-08 explicações por posição | PositionInsight, Tooltip e detalhes contextuais | position_hover_test, Web hover |
| R2-09 banner na tiragem | BannerAdSlot no rodapé, Home sem banner | home_ads_test; conta real de anúncio continua pendente |

A evidência da revisão está em docs/evidence/revision2. Os testes antigos de autosave e grade foram atualizados para o novo contrato, mantendo testes de persistência explícita, migrações, privacidade, cancelamento, revelação e drag. O texto abaixo é histórico e só vale onde não foi substituído pelos critérios R2.

---

# Rastreabilidade da elicitação

A solicitação atual acrescenta iOS e substitui o caminho antigo por `~/workspace/astra_projects/tarot_app`. Documento original não foi alterado. Código herdado foi copiado de `~/workspace/tarot_app`, commit 296854355d969c37fa3507ea94b94f85f25df7aa (incluindo estado local existente); nenhuma escrita feita nesse projeto original.

| Requisitos | Implementação | Evidência |
|---|---|---|
| BR-HARD-001/002/003/004/005/006/007, RF-010–020 | ReadingSession, ReadingController, RandomSource, Fisher–Yates | domain_test, randomization_test, elicitation_test |
| RF-001–003 | Home, recentReadingsProvider, catálogo de modos | widget_test, testes de navegação e smoke Web |
| RF-030–045 | Mesa compartilhada, drag validado, seleção fechada, undo/redo, revelação permanente | free_reading_test, manual_selection_test, ui-regressions.txt |
| RF-050–063 | SpreadCatalog, slots + complementares, sem limite por estrutura | elicitation_test (seis modos até 78), spread_reading_test |
| RF-054, RNF-043/053 | Reserva de rótulos; layouts responsivos e texto 200% | responsive_spreads_test |
| RF-070–076, BR-HARD-010 | 79 imagens locais e corpus PT-BR herdados, hashes conferidos | rws_deck_test, asset-audit.json, deck-provenance-manifest.json; revisão jurídica/editorial final pendente |
| RF-080–084 | Biblioteca, busca normalizada, filtros, detalhes e anterior/próxima | library_test |
| RF-090–103, RF-140–143, RNF-020–023 | SQLite/Drift, migrações 1→4, snapshots, autosave serializado, retry | persistence_test, free_reading_test, integração e smoke Web |
| RF-110–112, BR-HARD-009 | Resumo e JSON; pergunta/notas excluídas por padrão | journal_share_test |
| RF-120/121/124/125 | Temas, movimento reduzido, privacidade, créditos | settings_test; sem controles cenográficos de som/hápticos |
| RF-130–134/136, BR-HARD-008 | NoAds/StoreUnavailable padrão; adaptadores banner/compra única | home_ads_test, store_purchase_test; configuração e validação real de loja pendentes |
| RNF-070–074 | Domínio puro e portas; uma mesa para todos os spreads | architecture/boundaries_test |
| RT-001/002/007 | Unitários e widgets, regressões adicionadas | all-tests.txt |
| RT-003 | Fluxo com SQLite real e reinício da árvore de UI | integration_test/free_reading_test.dart; execução em device registrada separadamente |
| RT-004/005 | Chromium real, workers habilitados, draw/reveal/notes/reload/offline, watchdog | tool/web_acceptance.py, web-acceptance.json |
| RNF-080–082 | SDK identificado, lockfile, scripts de build/check | README, flutter-doctor.txt, logs de build |

## Diferencial desta tarefa (SDD/TDD)

1. Especificação escrita antes da mudança (`docs/spec/IMPLEMENTATION.md`).
2. Teste de domínio vermelho mostra chooseCard ausente (`tdd-red.txt`); implementação e testes verdes preservam retiradas/complementares (`tdd-green-domain.txt`).
3. Teste de interface vermelho demonstra ausência do seletor (`tdd-red-widget.txt`); seletor implementado e regressão de posicionamento cobre geometria ao fechar a seleção.
4. Smoke real encontrou loop de dois service workers (`web-regression-red.json`); bootstrap passou a registrar somente o worker offline próprio.
5. Teste de texto ampliado encontrou overflow do cabeçalho; marca passou a ajustar sua largura sem quebrar navegação.

## Itens não declarados completos

- RF-016: domínio suporta ponto de corte, UI oferece corte ao meio (P1 arquitetural atendido).
- RF-075: correspondências herméticas específicas não publicadas sem corpus aprovado.
- RF-113/122/123/135: imagem compartilhável, áudio, hápticos e créditos opcionais não implementados.
- RF-126/132/133: adaptador implementado, validação de transação real e restauração em sandbox pendentes.
- RT-006: testes cobrem controles centrais, porém não certificam auditoria exaustiva em todas as combinações/plataformas.
- RNF-010: fluidez em Android intermediário real ainda não medida.
- Release iOS/macOS/Windows/Linux e requisitos editoriais/jurídicos de produção: consultar VALIDATION.md.
