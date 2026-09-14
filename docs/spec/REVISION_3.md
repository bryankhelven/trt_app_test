# Arcanum — revisão 3: mesa manipulável

Esta revisão atende às correções do usuário e substitui a restrição anterior de manter cartas principais presas às posições. A elicitação é referência de produto; a solicitação explícita do usuário define estas alterações.

## Critérios de aceitação

- R3-01: qualquer carta pode sair de uma posição, ficar solta e voltar a uma posição vazia, sem consumir outra carta, perder revelação ou mudar a ordem de retirada. Posições são destinos de encaixe, não travas.
- R3-02: escolher uma carta do baralho não impõe o arcano da próxima posição. O filtro obrigatório existe apenas quando se escolhe diretamente uma posição de um par. Uma carta solta pode ser encaixada depois; a validação maior/menor permanece no encaixe.
- R3-03: na tiragem livre e nas cartas soltas, o título é “Carta X”, com X igual à ordem de retirada do baralho, mesmo depois de movimentos.
- R3-04: a mesa não exibe espaços ou marcadores antecipados de complemento. Somente depois de uma carta ser arrastada para perto ou sobre uma carta principal já encaixada ela aparece como complemento, sem substituir a principal. A numeração “1° complemento”, “2° complemento” segue a ordem de associação e é local à posição. Os dois arcanos de um par compartilham os complementos da posição.
- R3-05: complementos podem sair, voltar ou mudar de posição; a lista se renumera. Associação e ordem sobrevivem ao desfazer/refazer e ao salvamento explícito. A leitura de arquivos antigos continua funcionando.
- R3-06: rótulos não podem interceptar o arraste de cartas que estejam sob eles. Nas telas estreitas, reposicionar os rótulos centrais da Cruz Celta. Reservar uma faixa livre na mesa fixa para retirar e organizar cartas antes de encaixá-las. Manter cruzes, proporções e destinos acessíveis em retrato e paisagem; zoom amplia a mesa inteira.
- R3-07: animar chegada, encaixe/movimento e revelação. O arraste acompanha o ponteiro sem atraso. Respeitar a preferência de movimento reduzido e a configuração de acessibilidade do sistema. Nenhuma animação consome ou revela cartas por conta própria.
- R3-08: preservar tiragens temporárias, salvamento somente explícito, nova tiragem, seleção distribuída/percorrida, divisão de baralho e banner no rodapé.
- R3-09 (revisado para a beta Pages): a primeira instalação não deve recarregar a página. Uma atualização oferece “Atualizar agora”, para permitir salvar a tiragem antes de ativar o novo worker e recarregar uma única vez. Detalhes em `PAGES_BETA.md`.

## Modelo

`slotId` identifica a carta principal. `complementOf` identifica a posição lógica (sem sufixo maior/menor), e `associationOrder` registra a sequência de associação. Os papéis são exclusivos. Uma carta sem vínculo é solta. Os números de complemento são calculados a partir das associações atuais. Campos novos são opcionais no formato existente, para leitura compatível.

## Verificação

Testes primeiro para os movimentos, associações, sequência, compatibilidade e animações; testes de gestos para o fluxo real. Executar a suíte Flutter, análise estática e validação web. Compilação Android não equivale a execução em aparelho.
