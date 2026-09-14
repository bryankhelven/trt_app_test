# ELICITAÇÃO DE REQUISITOS — TAROT APP
## Requisitos Funcionais e Não Funcionais

**Documento:** TAROT_APP_REQUIREMENTS_ELICITATION_V1  
**Status:** Baseline canônico para implementação e auditoria  
**Produto:** Aplicativo de Tarot Hermético  
**Plataformas-alvo:** Android (primária), Web e Windows/desktop  
**Stack prevista:** Flutter / Dart  
**Modelo operacional:** local-first, offline-capable  
**Idioma inicial:** Português do Brasil  
**Repositório canônico de desenvolvimento:** `~/workspace/tarot_app` no WSL  

---

# 1. OBJETIVO DO DOCUMENTO

Este documento consolida os requisitos funcionais e não funcionais do aplicativo de Tarot discutido e prototipado ao longo do projeto.

Seu propósito é:

1. servir como fonte canônica de requisitos de produto;
2. reduzir ambiguidades entre Product Owner e agentes de implementação;
3. permitir rastreabilidade entre requisito, código, teste e critério de aceite;
4. impedir regressões conceituais, especialmente no modelo de interação das tiragens;
5. estabelecer uma Definition of Done verificável para a v1;
6. separar requisitos de produto de decisões técnicas de implementação.

Este documento deve ser lido em conjunto com ADRs, especificações de arquitetura, estratégia de testes e Definition of Done existentes no repositório.

---

# 2. VISÃO DO PRODUTO

O aplicativo deve reproduzir uma experiência digital de uso do Tarot próxima do manuseio de um baralho físico, preservando:

- autonomia do usuário;
- escolha ritual/intuitiva das cartas;
- possibilidade de embaralhar e cortar;
- liberdade para retirar cartas adicionais;
- leitura não automatizada;
- visual contemplativo e coerente com um Tarot Hermético;
- privacidade local-first;
- funcionamento offline;
- suporte a Android, Web e desktop.

O aplicativo **não deve agir como um “gerador automático de tiragens”**.

A regra conceitual central é:

> **O aplicativo oferece um baralho e uma estrutura de tiragem. Quem tira as cartas é o usuário.**

---

# 3. ESCOPO DA V1

A v1 deverá incluir:

- baralho Rider-Waite-Smith histórico/public-domain com 78 cartas;
- Tiragem Livre;
- seis tiragens predefinidas;
- interação manual com o baralho;
- embaralhar;
- cortar;
- escolher uma carta entre as cartas restantes;
- cartas complementares além das posições principais;
- Biblioteca das 78 cartas;
- conteúdo editorial original em PT-BR;
- Diário/Histórico;
- perguntas e notas;
- persistência local;
- exportação/compartilhamento;
- configurações;
- monetização preparada para Android;
- compra para remover anúncios;
- arquitetura extensível para features premium;
- identidade visual final;
- acessibilidade básica;
- validação Web e Android.

---

# 4. FORA DE ESCOPO DA V1

Não fazem parte obrigatória da v1:

- backend próprio;
- contas de usuário;
- login;
- cloud sync;
- rede social;
- chat;
- marketplace de decks;
- assinatura mensal obrigatória;
- IA generativa para interpretar tiragens;
- cartas invertidas;
- integração com terceiros para armazenamento de notas;
- rewarded-video fullscreen enquanto a regra de “zero fullscreen ads” estiver ativa;
- dezenas de decks adicionais.

---

# 5. ATORES

## ACT-001 — Usuário / Consulente

Pessoa que utiliza o aplicativo para:

- realizar tiragens;
- escolher cartas;
- consultar significados;
- salvar leituras;
- registrar perguntas e notas;
- consultar histórico;
- configurar preferências;
- adquirir remoção de anúncios.

## ACT-002 — Product Owner / Curador editorial

Responsável por:

- aprovar conteúdo editorial;
- definir orientação hermética;
- decidir identidade comercial;
- aprovar conteúdo doutrinário;
- decidir features premium;
- autorizar mudanças em regras HARD.

## ACT-003 — Plataforma Android / Google Play

Responsável por:

- distribuição do app Android;
- billing;
- restauração de compras;
- políticas de anúncios;
- consentimento;
- Data Safety.

---

# 6. REGRAS DE NEGÓCIO HARD

## BR-HARD-001 — Sem cartas invertidas

O aplicativo segue uma escola de Tarot Hermético que **não utiliza cartas invertidas**.

É proibido introduzir:

- `reversed`;
- `upright/reversed`;
- rotação semântica de 180°;
- meanings invertidos;
- settings de reversão;
- randomização de orientação.

Transformações visuais temporárias de UI não podem produzir significado de reversão.

## BR-HARD-002 — Retirada sem reposição

Uma carta retirada do deck não pode ser retirada novamente na mesma leitura.

## BR-HARD-003 — Um spread não limita o número máximo de cartas

O número de posições principais de uma tiragem não é o máximo de cartas da leitura.

Exemplo:

- Relação: 5 posições principais;
- o usuário pode retirar 6, 7, 8... cartas complementares;
- o limite real é o esgotamento das 78 cartas.

Formalmente:

`coreCardCount != maxReadingCards`

## BR-HARD-004 — Tiragens não distribuem cartas automaticamente

Nenhuma tiragem predefinida pode auto-deal as cartas.

Slots começam vazios.

O usuário decide quando e como retirar cada carta.

## BR-HARD-005 — Tiragem Livre não possui limite artificial

Na Tiragem Livre, o usuário pode retirar e colocar cartas livremente até o deck ser esgotado.

## BR-HARD-006 — O usuário controla o ritual

Embaralhar e cortar são opcionais.

O usuário pode iniciar a leitura imediatamente ou:

- embaralhar;
- cortar;
- escolher uma carta;
- retirar do topo.

## BR-HARD-007 — Cartas principais e complementares

Uma leitura predefinida pode conter:

- `core placements`: cartas ligadas às posições estruturais do spread;
- `auxiliary placements`: cartas adicionais e livres.

## BR-HARD-008 — Sem publicidade fullscreen

São proibidos:

- interstitial;
- app-open ad;
- rewarded-interstitial;
- fullscreen ad forçado;
- anúncio sobre a mesa de leitura.

## BR-HARD-009 — Privacidade das leituras

Perguntas, notas e conteúdo de uma leitura:

- permanecem locais na v1;
- não podem ser enviados para analytics;
- não podem aparecer em crash logs;
- não podem ser enviados a terceiros sem ação explícita do usuário.

## BR-HARD-010 — Proveniência dos assets

Toda arte de produção precisa possuir:

- fonte;
- autoria;
- status de copyright/licença;
- URL/referência;
- hash;
- data de aquisição;
- notas de transformação.

---

# 7. REQUISITOS FUNCIONAIS

## 7.1 Inicialização e Home

### RF-001 — Home

O sistema deve exibir uma Home contendo acesso a:

- Tiragem Livre;
- Carta Única;
- Passado / Presente / Futuro;
- Situação / Obstáculo / Conselho;
- Relação;
- Ferradura;
- Cruz Celta;
- Biblioteca;
- Diário/Histórico;
- Configurações;
- Premium/Remover anúncios, quando aplicável.

**Prioridade:** P0

### RF-002 — Retomar leitura ativa

Quando houver leitura ativa/autosalva, a Home deve permitir sua retomada.

**Prioridade:** P1

### RF-003 — Leituras recentes

A Home deve poder exibir acesso às leituras recentes sem substituir o Diário completo.

**Prioridade:** P1

## 7.2 Deck e motor de cartas

### RF-010 — Deck de 78 cartas

O sistema deve carregar exatamente 78 cartas únicas no baralho inicial.

**Prioridade:** P0

### RF-011 — Ordem inicial aleatória

Ao iniciar uma nova leitura, o deck deve possuir uma ordem aleatória segura.

**Prioridade:** P0

### RF-012 — Fisher-Yates

O embaralhamento deve utilizar algoritmo Fisher-Yates ou equivalente comprovadamente imparcial.

**Prioridade:** P0

### RF-013 — Fonte de entropia segura

A randomização de produção deve utilizar fonte criptograficamente segura.

**Prioridade:** P0

### RF-014 — Embaralhar restantes

O usuário deve poder embaralhar somente as cartas ainda não retiradas.

O sistema não pode alterar cartas já colocadas na mesa.

**Prioridade:** P0

### RF-015 — Cortar ao meio

O usuário deve poder cortar a pilha restante ao meio.

A operação deve:

- preservar todas as cartas;
- não duplicar;
- não remover;
- não alterar cartas já retiradas;
- persistir a nova ordem.

**Prioridade:** P0

### RF-016 — Cortar em ponto escolhido

O sistema deve ser arquiteturalmente capaz de permitir ao usuário escolher um ponto de corte.

**Prioridade:** P1

### RF-017 — Retirar carta do topo

O usuário deve poder retirar a carta superior do deck através de drag.

**Prioridade:** P0

### RF-018 — Escolher uma carta intuitivamente

Ao tocar/clicar no deck, o sistema deve disponibilizar uma interface de escolha entre as cartas restantes, todas viradas para baixo.

O usuário deve poder selecionar uma posição específica.

**Prioridade:** P0

### RF-019 — Escolha sem revelar

A interface de escolha não pode revelar a face da carta antes da seleção.

**Prioridade:** P0

### RF-020 — Persistência da ordem restante

Shuffle, cut e escolha de carta devem atualizar e persistir a ordem restante do deck.

**Prioridade:** P0

## 7.3 Tiragem Livre

### RF-030 — Deck acessível na Tiragem Livre

O deck deve permanecer acessível em área fixa da tela, inicialmente no canto superior direito.

**Prioridade:** P0

### RF-031 — Retirada manual

Nenhuma carta deve ser distribuída automaticamente na Tiragem Livre.

**Prioridade:** P0

### RF-032 — Drag do deck

Ao arrastar uma carta do deck, o centro visual da carta deve acompanhar o ponteiro/toque.

**Prioridade:** P0

### RF-033 — Drop arbitrário

O usuário deve poder soltar cartas em qualquer posição válida da mesa.

**Prioridade:** P0

### RF-034 — Drag inválido

Se o usuário cancelar o drag ou soltar em área inválida:

- nenhuma carta é consumida;
- a ordem do deck permanece consistente.

**Prioridade:** P0

### RF-035 — Carta fechada ao ser colocada

Uma carta recém-colocada deve iniciar virada para baixo.

**Prioridade:** P0

### RF-036 — Primeiro toque revela

O primeiro tap/click numa carta fechada deve revelar a carta.

**Prioridade:** P0

### RF-037 — Segundo toque abre detalhes

O próximo tap/click numa carta revelada deve abrir suas informações.

**Prioridade:** P0

### RF-038 — Drag não é tap

Arrastar uma carta não pode acionar reveal ou abrir detalhes ao soltar.

**Prioridade:** P0

### RF-039 — Carta revelada continua movível

Cartas reveladas continuam podendo ser reposicionadas.

**Prioridade:** P0

### RF-040 — Modal sobre a mesa

O modal de detalhes deve estar acima de:

- cartas;
- deck;
- mesa;
- labels.

**Prioridade:** P0

### RF-041 — Quantidade livre

O usuário pode retirar cartas até o deck se esgotar.

**Prioridade:** P0

### RF-042 — Tamanho de cartas

Na Tiragem Livre, as cartas devem ser significativamente menores que em visualizações de foco, visando alta densidade de mesa.

O baseline original é aproximadamente 25% do tamanho padrão legado, sujeito a limites responsivos.

**Prioridade:** P1

### RF-043 — Z-order

Ao mover uma carta, o sistema deve trazê-la visualmente à frente enquanto necessário.

**Prioridade:** P1

### RF-044 — Undo/Redo

A Tiragem Livre deve suportar desfazer/refazer ações apropriadas.

**Prioridade:** P1

### RF-045 — Revelação permanente

Na v1, revelar uma carta é uma ação permanente dentro da leitura, não revertida por undo.

**Prioridade:** P1

## 7.4 Tiragens predefinidas

### RF-050 — Spreads data-driven

Tiragens predefinidas devem ser definidas por dados, não por engines separados.

**Prioridade:** P0

### RF-051 — Slots inicialmente vazios

Ao abrir uma tiragem predefinida, todos os slots começam vazios.

**Prioridade:** P0

### RF-052 — Sem auto-deal

O sistema não pode preencher automaticamente os slots.

**Prioridade:** P0

### RF-053 — Preenchimento manual

O usuário deve retirar cada carta manualmente e colocá-la num slot.

**Prioridade:** P0

### RF-054 — Labels sempre visíveis

Cada slot deve reservar área própria para:

- carta;
- nome/label do slot.

A carta não pode cobrir o label.

**Prioridade:** P0

### RF-055 — Slots principais não limitam leitura

Após preencher todos os slots principais, o deck continua ativo.

**Prioridade:** P0

### RF-056 — Cartas complementares

Após preencher os slots principais, o usuário pode colocar cartas adicionais livremente.

**Prioridade:** P0

### RF-057 — Status não terminal

A interface não deve usar “Tiragem completa” como estado que bloqueia a leitura.

Pode exibir:

- “5/5 posições principais”;
- “Estrutura principal preenchida”.

**Prioridade:** P0

### RF-058 — Carta Única

Implementar tiragem de 1 posição principal.

Cartas adicionais continuam permitidas.

**Prioridade:** P0

### RF-059 — Passado / Presente / Futuro

Implementar tiragem de 3 posições principais.

**Prioridade:** P0

### RF-060 — Situação / Obstáculo / Conselho

Implementar tiragem de 3 posições principais.

**Prioridade:** P0

### RF-061 — Relação

Implementar tiragem de 5 posições principais:

- Você;
- A outra pessoa;
- O vínculo entre vocês;
- Desafio;
- Caminho possível.

**Prioridade:** P0

### RF-062 — Ferradura

Implementar tiragem de 7 posições principais.

**Prioridade:** P0

### RF-063 — Cruz Celta

Implementar tiragem de 10 posições principais.

**Prioridade:** P0

## 7.5 Conteúdo das cartas

### RF-070 — Artwork real

As 78 cartas devem utilizar artwork histórico RWS validado juridicamente.

**Prioridade:** P0

### RF-071 — Assets locais

As imagens devem ser empacotadas localmente.

**Prioridade:** P0

### RF-072 — Verso da carta

O aplicativo deve possuir um verso visualmente coerente.

**Prioridade:** P0

### RF-073 — Conteúdo PT-BR

Cada carta deve possuir conteúdo editorial original em PT-BR.

**Prioridade:** P0

### RF-074 — Campos mínimos

Cada carta deve possuir, no mínimo:

- nome canônico;
- palavras-chave;
- interpretação curta;
- interpretação estendida;
- simbolismo.

**Prioridade:** P0

### RF-075 — Conteúdo Hermético

Campos específicos de Tarot Hermético podem incluir:

- elemento;
- astrologia;
- letra hebraica;
- caminho na Árvore da Vida;
- decanato;
- dignidades.

Somente devem ser publicados quando editorialmente aprovados.

**Prioridade:** P1

### RF-076 — Sem meanings invertidos

Nenhuma carta deve possuir conteúdo de reversed meaning.

**Prioridade:** P0

## 7.6 Biblioteca

### RF-080 — Biblioteca completa

O sistema deve disponibilizar as 78 cartas para consulta.

**Prioridade:** P0

### RF-081 — Filtros por categoria

O usuário deve poder filtrar por:

- Arcanos Maiores;
- Paus;
- Copas;
- Espadas;
- Ouros.

**Prioridade:** P1

### RF-082 — Busca

O usuário deve poder buscar por:

- nome;
- palavra-chave.

**Prioridade:** P1

### RF-083 — Detalhe da carta

O detalhe deve exibir:

- artwork;
- título;
- keywords;
- interpretação;
- simbolismo;
- metadados aprovados.

**Prioridade:** P0

### RF-084 — Navegação anterior/próxima

O detalhe pode permitir navegação sequencial entre cartas.

**Prioridade:** P2

## 7.7 Diário e Histórico

### RF-090 — Salvar leitura

O sistema deve salvar leituras localmente.

**Prioridade:** P0

### RF-091 — Autosave

Mudanças relevantes devem ser autosalvas.

**Prioridade:** P0

### RF-092 — Histórico

O usuário deve poder visualizar leituras anteriores.

**Prioridade:** P0

### RF-093 — Informações de histórico

Cada leitura deve registrar:

- data/hora;
- modo/spread;
- cartas;
- estados revelados;
- posições;
- pergunta opcional;
- notas;
- versão do deck/conteúdo.

**Prioridade:** P0

### RF-094 — Reabrir detalhes

O usuário deve poder consultar os dados completos de uma leitura passada.

**Prioridade:** P0

### RF-095 — Excluir leitura

O usuário deve poder excluir uma leitura com confirmação.

**Prioridade:** P1

### RF-096 — Restaurar sessão

A arquitetura deve suportar restauração exata da sessão ativa após reload/restart.

**Prioridade:** P0

## 7.8 Pergunta e notas

### RF-100 — Pergunta opcional

O usuário pode registrar uma pergunta para a leitura.

**Prioridade:** P1

### RF-101 — Notas livres

O usuário pode registrar notas em texto livre.

**Prioridade:** P1

### RF-102 — Persistência

Pergunta e notas devem sobreviver a reload/restart.

**Prioridade:** P0

### RF-103 — Privacidade

Pergunta e notas não podem ser enviadas a analytics/logs.

**Prioridade:** P0

## 7.9 Exportação e compartilhamento

### RF-110 — Compartilhar resumo

O usuário deve poder compartilhar/exportar resumo da leitura.

**Prioridade:** P1

### RF-111 — Opt-in de dados privados

Pergunta/notas somente podem entrar no compartilhamento mediante ação explícita do usuário.

**Prioridade:** P0

### RF-112 — Export JSON

O sistema deve permitir exportar dados estruturados de leitura em JSON.

**Prioridade:** P1

### RF-113 — Imagem compartilhável

O sistema deve, se tecnicamente viável na v1, gerar uma imagem da tiragem para compartilhamento.

**Prioridade:** P2

## 7.10 Configurações

### RF-120 — Tema

O sistema deve permitir:

- claro;
- escuro;
- sistema.

**Prioridade:** P1

### RF-121 — Movimento reduzido

O sistema deve oferecer preferência de movimento reduzido.

**Prioridade:** P1

### RF-122 — Som

Caso sons sejam implementados, deve haver opção de ativar/desativar.

**Prioridade:** P2

### RF-123 — Hápticos

Caso hápticos sejam implementados no Android, deve haver opção de ativar/desativar.

**Prioridade:** P2

### RF-124 — Privacidade

A tela de configurações deve conter informação de privacidade.

**Prioridade:** P0

### RF-125 — Créditos/licenças

O usuário deve poder consultar:

- créditos do deck;
- licenças;
- proveniência resumida;
- versão do app.

**Prioridade:** P0

### RF-126 — Restaurar compras

O app Android deve permitir restaurar entitlements quando aplicável.

**Prioridade:** P1

## 7.11 Monetização

### RF-130 — Anúncios permitidos

São permitidos:

- banner;
- native ads.

**Prioridade:** P1

### RF-131 — Áreas sem anúncio

Não pode haver anúncios sobre:

- mesa ativa;
- cartas;
- slots;
- modal de leitura.

**Prioridade:** P0

### RF-132 — Remover anúncios

O usuário deve poder adquirir entitlement `remove_ads`.

**Prioridade:** P1

### RF-133 — Compra única

`remove_ads` deve ser uma compra única.

**Prioridade:** P1

### RF-134 — Features premium futuras

A arquitetura deve suportar entitlements adicionais.

**Prioridade:** P2

### RF-135 — Créditos

O sistema pode possuir arquitetura de CreditLedger para futura economia de créditos.

**Prioridade:** P2

### RF-136 — Rewarded video

Rewarded video não deve ser ativado enquanto qualquer formato fullscreen continuar proibido.

**Prioridade:** HARD

## 7.12 Offline e persistência

### RF-140 — Core offline

O usuário deve conseguir:

- abrir o app;
- fazer tiragens;
- consultar cartas;
- salvar;
- acessar histórico;

sem conexão.

**Prioridade:** P0

### RF-141 — Conteúdo bundled

Deck, conteúdo editorial e recursos essenciais devem ser locais.

**Prioridade:** P0

### RF-142 — Persistência Web

A aplicação Web deve persistir dados através da solução suportada pelo stack, preferencialmente OPFS/SQLite quando disponível.

**Prioridade:** P0

### RF-143 — Fallback Web

Se o navegador não suportar a persistência ideal, o sistema deve falhar de forma controlada e explicar a limitação.

**Prioridade:** P1

---

# 8. REQUISITOS NÃO FUNCIONAIS

## 8.1 Usabilidade

### RNF-001 — Interação autoexplicativa

A interface deve permitir o uso básico sem tutorial extenso.

### RNF-002 — Sem botões cenográficos

Todo controle visível e habilitado deve produzir efeito observável.

### RNF-003 — Mesa como foco

Durante uma leitura, a mesa deve ser o elemento visual dominante.

### RNF-004 — Feedback de ação

Ações como embaralhar, cortar, salvar e nova leitura devem fornecer feedback visível.

### RNF-005 — Labels legíveis

Labels de slots não podem ser cobertos pelas cartas.

## 8.2 Performance

### RNF-010 — Drag fluido

Arrastar cartas deve ocorrer sem jank perceptível em hardware Android intermediário.

### RNF-011 — Startup

A Home deve aparecer em tempo aceitável sem dependência de rede.

### RNF-012 — Assets otimizados

As 78 imagens devem ser otimizadas para reduzir memória, tamanho do APK/Web bundle e tempo de decodificação.

### RNF-013 — Scroll fluido

Biblioteca e Diário devem manter scroll fluido.

## 8.3 Confiabilidade

### RNF-020 — Autosave serializado

Escritas de autosave devem evitar condição de corrida em que snapshot antigo sobrescreva novo.

### RNF-021 — Migrações

Mudanças de schema devem preservar dados existentes.

### RNF-022 — Recuperação

Falhas de persistência devem ser tratadas sem perda silenciosa de dados.

### RNF-023 — Determinismo de testes

Randomização deve ser injetável para testes determinísticos.

## 8.4 Segurança e privacidade

### RNF-030 — Local-first

Dados de leitura devem permanecer no dispositivo na v1.

### RNF-031 — Sem analytics de conteúdo

Perguntas/notas não podem integrar payloads de analytics.

### RNF-032 — Sem logs sensíveis

Perguntas/notas não podem aparecer em logs de erro.

### RNF-033 — Consentimento

SDKs de anúncios devem respeitar consentimento quando legalmente necessário.

## 8.5 Compatibilidade

### RNF-040 — Android-first

Android é a plataforma primária de release.

### RNF-041 — Web funcional

A aplicação Web deve ser funcional, não apenas compilável.

### RNF-042 — Windows compatível

A arquitetura deve permanecer compatível com Flutter Windows.

### RNF-043 — Responsividade

O layout deve funcionar em smartphone portrait, smartphone landscape, tablet, desktop browser e janela redimensionável.

### RNF-044 — Touch + mouse

A mesma feature deve funcionar com touch, mouse e trackpad quando aplicável.

## 8.6 Acessibilidade

### RNF-050 — Semantics

Controles principais devem possuir labels semânticos.

### RNF-051 — Contraste

Texto e controles devem ter contraste adequado.

### RNF-052 — Tamanho de toque

Targets de interação devem possuir tamanho apropriado.

### RNF-053 — Escala de texto

O app deve tolerar aumento de escala de texto sem quebrar layout crítico.

### RNF-054 — Cor não exclusiva

Informação não pode depender exclusivamente de cor.

### RNF-055 — Reduced motion

Animações devem respeitar a preferência de movimento reduzido quando possível.

## 8.7 Visual / identidade

### RNF-060 — Linguagem visual

O produto deve transmitir contemplação, atmosfera hermética, elegância, profundidade e seriedade.

### RNF-061 — Evitar estética genérica

Evitar aparência de demo Flutter, dashboard corporativo, cassino, neon excessivo ou UI esotérica kitsch.

### RNF-062 — Paleta

A paleta pode utilizar floresta/teal/índigo escuro, dourado/latão discreto e pergaminho/marfim.

### RNF-063 — Mesa atmosférica

A mesa deve possuir textura/gradiente/profundidade visual sutil.

## 8.8 Manutenibilidade

### RNF-070 — Domain independente

Domínio não deve depender diretamente de Flutter UI, AdMob, Play Billing, SQLite ou APIs Android.

### RNF-071 — Adapters

Anúncios, billing, analytics e persistência devem ser acessados por interfaces/ports.

### RNF-072 — Spreads data-driven

Adicionar novo spread não deve exigir criar novo engine.

### RNF-073 — Testabilidade

Domínio deve ser testável sem UI.

### RNF-074 — Git como autoridade

Estado compartilhado entre agentes deve ser repositório + documentação + testes, não memória de conversa.

## 8.9 Reprodutibilidade

### RNF-080 — Dependências fixadas

Versões críticas devem estar registradas.

### RNF-081 — Toolchain documentado

Flutter/Dart e comandos de build devem estar documentados.

### RNF-082 — Build verificável

O projeto deve fornecer comandos claros para test, analyze, build Web, build Android e run Web.

---

# 9. REQUISITOS DE TESTE

## RT-001 — Unit tests

Obrigatórios para domínio, randomização, draw without replacement, shuffle, cut, chooseCard, persistência, migrations e entitlements.

## RT-002 — Widget tests

Obrigatórios para reveal, modal, drag, labels, menus, Biblioteca, Diário e Settings.

## RT-003 — Integration tests

Cobrir iniciar leitura, retirar cartas, revelar, abrir detalhes, salvar, reload e restaurar.

## RT-004 — Real browser smoke

Web deve ser testado em navegador real.

## RT-005 — Download/reload watchdog

O teste Web deve detectar download inesperado, navegação para assets internos, reload loop, pageerror e console error fatal.

## RT-006 — UI Completeness Gate

Todo controle habilitado visível deve ser inventariado, acionado e possuir efeito verificável.

## RT-007 — Regressão por bug

Todo bug P0/P1 corrigido deve receber teste de regressão quando tecnicamente possível.

---

# 10. CRITÉRIOS DE ACEITE TRANSVERSAIS

## CA-001
Nenhuma carta pode aparecer duas vezes na mesma leitura.

## CA-002
Nenhum spread pode impedir cartas complementares apenas por seus core slots já estarem preenchidos.

## CA-003
Nenhuma tiragem predefinida pode auto-deal.

## CA-004
Tiragem Livre permite retirada manual até o deck acabar.

## CA-005
Escolher uma carta não revela sua face previamente.

## CA-006
Slots ocupados continuam exibindo seus labels.

## CA-007
Reload restaura posições, reveal state, core/auxiliary placements, ordem restante, notas e pergunta.

## CA-008
Nenhum botão habilitado pode ser no-op.

## CA-009
Nenhuma feature de reversão pode aparecer no domínio ou UI.

## CA-010
Nenhum anúncio fullscreen pode existir.

---

# 11. DECISÕES EM ABERTO

## OD-001 — Nome comercial
Definir nome final do app.

## OD-002 — Application ID
Definir `applicationId` definitivo antes da primeira publicação.

## OD-003 — Ícone
Criar ícone final Android/Web.

## OD-004 — Autoridade hermética
Definir corpus/autores que serão autoridade para correspondências específicas.

## OD-005 — Premium
Definir features pagas adicionais além de Remove Ads.

## OD-006 — Créditos
Definir utilidade concreta da economia de créditos.

## OD-007 — Rewarded video
Somente reconsiderar se o Product Owner decidir aceitar fullscreen voluntário.

## OD-008 — Segundo deck
Avaliar Marseille/Sola Busca em versões futuras.

---

# 12. MATRIZ DE PRIORIDADE

## P0 — Release blocker

Requisitos cuja ausência impede considerar a v1 funcional:

- deck de 78;
- sem reversões;
- draw without replacement;
- Tiragem Livre;
- tiragens predefinidas;
- interação manual;
- cartas complementares;
- artwork real;
- conteúdo editorial;
- persistência;
- Biblioteca;
- Diário;
- core offline;
- privacidade;
- Web funcional;
- Android build.

## P1 — Importante para v1

- Remove Ads;
- tema;
- notas/pergunta;
- export;
- busca;
- cut avançado;
- acessibilidade básica.

## P2 — Pode ser pós-v1

- navegação avançada na Biblioteca;
- imagem compartilhável sofisticada;
- créditos;
- features premium adicionais;
- segundo deck.

---

# 13. DEFINITION OF DONE — V1

A v1 só pode ser declarada DONE quando:

1. o app não auto-distribui cartas;
2. o usuário controla retirada, shuffle e cut;
3. Tiragem Livre aceita cartas até deck exhaustion;
4. todos os spreads permitem cartas além dos core slots;
5. labels não são cobertos;
6. escolha intuitiva de carta funciona;
7. as 78 cartas reais estão incorporadas;
8. o corpus PT-BR está completo;
9. Biblioteca funciona;
10. Diário funciona;
11. notas/pergunta persistem;
12. Settings funciona;
13. export funciona;
14. offline funciona;
15. Web abre em navegador real sem loops/downloads indevidos;
16. Android compila e roda em dispositivo/emulador;
17. todos os controles habilitados funcionam;
18. todos os testes obrigatórios estão GREEN;
19. não existe reversão;
20. não existe anúncio fullscreen;
21. nenhum P0/P1 conhecido permanece aberto;
22. evidências e relatórios estão atualizados.

---

# 14. PRINCÍPIO FINAL DE PRODUTO

A semântica central do aplicativo deve permanecer:

> **A tiragem organiza o espaço. O baralho oferece as cartas. O usuário conduz a leitura.**

O sistema não deve substituir o ato de tirar cartas pelo usuário.
