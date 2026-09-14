# Validação — Arcanum 1.2.0+3, revisão 3

A revisão implementa o pedido corrigido do usuário, especificado em docs/spec/REVISION_3.md. O documento de requisitos original permanece preservado. Este relatório registra a validação anterior à hospedagem; a publicação da beta web e suas verificações estão em [DEPLOYMENT.md](DEPLOYMENT.md). Não houve cobrança.

## Verificações desta revisão

| Verificação | Resultado | Evidência |
|---|---|---|
| Domínio, snapshots explícitos, nove estruturas pareadas, interface, seleção, privacidade e monetização | 107 testes passaram | docs/evidence/revision3/all-tests.txt |
| Análise estática | Sem apontamentos | docs/evidence/revision3/analyze.txt |
| Geometria e limites em retrato/paisagem, zoom disponível, texto 200% | Testes passaram | test/features/responsive_spreads_test.dart |
| Hover contextual sem revelar identidade fechada | Testes passaram | test/features/position_hover_test.dart |
| Rótulos bloqueavam o arraste de uma carta sob eles | Reproduzido em vermelho; rótulos agora ignoram ponteiros | docs/evidence/revision3/label-drag-red.txt e suíte final |
| Movimento, complementos, numeração e animações | Testes vermelhos antes da implementação; suíte final verde | docs/evidence/revision3/tdd-red.txt, gestures-motion-red.txt e all-tests.txt |
| Build Web com recursos locais | Passou | docs/evidence/revision3/build-web.txt |
| Primeira abertura sem cache anterior | Passou na origem limpa `localhost:8881`; a instalação offline não interrompeu a tela | validação web R3 |
| Navegador real: escolher, arrastar, encaixar, retirar, associar e renumerar complementos, hover, salvar/reabrir, orientação, pares, cruzes e offline | Passou: Chromium real, zero erros nos fluxos testados | docs/evidence/revision3/web-acceptance.json |
| APKs ARMv7, ARM64 e x86_64 | Compilaram: ARMv7, ARM64 e x86_64; tamanhos e hashes no manifesto de artefatos | docs/evidence/revision3/build-android.txt, android-artifacts.json |
| Integração Flutter em dispositivo | Cenário atualizado para salvamento explícito; não executado nesta revisão | integration_test/free_reading_test.dart |
| iOS/macOS/Windows/Linux nativos | Não compilados/executados neste host | projetos incluídos; dependências GTK/clang/ninja ausentes no WSL |

## Comportamento entregue

- Todas as cartas podem sair de posições e voltar. Escolher diretamente no baralho permite selecionar qualquer arcano; o encaixe em maior/menor valida o tipo no destino.
- Área livre para organizar retiradas. Não há marcador antecipado de complemento: soltar perto ou sobre uma carta principal ocupada faz o complemento aparecer. A numeração é local por ordem de associação, compartilhada pelo par maior+menor. Retirar ou mover um complemento atualiza a sequência.
- Cartas soltas têm título “Carta X” pela ordem de retirada, preservado ao mover. Associação e número aparecem no hover, diário e exportação.
- Animações de retirada, chegada, encaixe/movimento e revelação. Preferência de movimento reduzido do aplicativo ou sistema suprime as animações da mesa.
- Cartas maiores nas tiragens simples; área livre comporta uma carta inteira. Rótulos não interceptam gestos; os centrais da Cruz Celta mudam de lugar em telas estreitas.

- Tiragem temporária, salvo somente por ação explícita. Edições posteriores não alteram o último snapshot até novo salvamento. Nova tiragem não apaga entradas já salvas. Recarregar/fechar o app descarta a memória; segundo plano e rotação a mantêm enquanto o processo estiver aberto.
- Diário abre o snapshot na mesa. Leituras persistidas pela primeira versão foram preservadas como dados históricos; não houve apagamento retroativo sem consentimento.
- Dez modos, incluindo Se sim/Se não, Quatro elementos e Cruz Hermética com as onze posições pedidas. Maior+menor por posição é opção anterior à primeira retirada em qualquer uma das nove estruturas.
- A geometria não vira grade ao girar a tela. Cabeçalho compacto em paisagem curta, verso próprio e banner no rodapé da tiragem. Em telas pequenas, ampliar a mesa permite examinar as figuras de maior densidade; os detalhes oferecem a carta em tamanho de leitura.
- Distribuídas, percorrer e dividir em 2/3 montes; filtros de maiores/menores não expõem identidades ou reintroduzem retiradas. Os complementos mantêm a referência à posição no painel flutuante.
- O popover relaciona conteúdo editorial à posição por uma pergunta-guia. Não gera previsão personalizada nem inventa uma análise das combinações de cartas.

## Limites que permanecem para publicação

1. Configuração das contas, produtos, IDs definitivos, preços e consentimento. Banner real é Android e depende de ANDROID_BANNER_ID. Web/desktop e iOS estão sem anúncios. Ausência de configuração não exibe um banner fictício. Compra única mantém adaptador e testes; verificação independente de recibos, estornos/revogações e testes reais de loja continuam pendentes.
2. APK local otimizado usa assinatura de desenvolvimento e applicationId provisório. Não é pacote final para publicar nas lojas. Não foi validado em aparelho físico; a tentativa de emulador da primeira entrega foi inconclusiva e não é apresentada como teste aprovado.
3. Builds e testes nativos iOS/macOS/Windows/Linux precisam dos respectivos hosts/ferramentas. A versão Web foi testada em dimensões móveis com Chromium, sem substituir validação touch e desempenho em aparelhos reais.
4. Revisão editorial/jurídica final do corpus e proveniência das artes permanece pendente. Os assets herdados não foram alterados. O verso agora é vetorial próprio (ArcanumCardBack); o PNG histórico não é usado nas cartas fechadas.
5. Web exige os cabeçalhos COOP/COEP fornecidos para OPFS. Offline funciona após a primeira carga e instalação do cache; sem sincronização entre dispositivos. Uma atualização do service worker é aplicada ao fechar as abas da versão anterior; não força recarga de uma tiragem temporária.
6. Compartilhamento de imagem, áudio, vibração, outros decks e créditos virtuais permanecem opcionais não implementados, como registrado anteriormente.

Os relatórios anteriores a docs/evidence/revision3 são históricos; não substituem as evidências desta revisão. O aviso de múltiplas instâncias Drift em testes é de infraestrutura de teste; falhas e apontamentos da suíte são registrados separadamente.

## Observações sobre a automação Web

Os menus Flutter expõem seus itens por role=menuitem e aria-label, sem texto no corpo do DOM. O teste os aciona por esses nomes acessíveis. Para clicar no baralho sob um tooltip, o teste usa movimento/clique real do mouse sobre a posição consultada: a árvore de acessibilidade pode manter um nó textual sobreposto, enquanto IgnorePointer controla corretamente o acerto no canvas. Não há injeção de estado da tiragem. Essas diferenças do espelho DOM foram separadas das falhas reais de interface.
