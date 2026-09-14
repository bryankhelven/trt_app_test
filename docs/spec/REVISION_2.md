# Arcanum — revisão orientada pelo pedido atual

Esta especificação prevalece sobre decisões incompatíveis da implementação anterior e do anexo. Fonte visual: docs/baseline/visual-reference.png. Não importar novamente código do projeto descartado.

## Critérios de aceite
- R2-01: sessão temporária em memória, zero gravações automáticas. Salvar tiragem grava um snapshot explícito; alterações posteriores exigem novo toque em Salvar. Sair da mesa, nova tiragem ou fechar/recarregar o processo descarta o não salvo. Segundo plano mantém memória; rotação nunca descarta. Dados salvos anteriormente não serão apagados como parte desta migração.
- R2-02: Nova tiragem e Salvar tiragem visíveis na mesa. Aviso permanente de temporariedade; iniciar outra confirma descarte se houver alterações. Diário contém somente snapshots persistidos.
- R2-03: geometria normalizada projetada conforme largura E altura; retrato/paisagem sem grade substitutiva das figuras. Cruz Celta desenhada (centro com desafio transversal, braços e coluna lateral). Complementares podem sobrepor parcialmente faces, com rótulos desenhados acima delas e sem substituir posições ocupadas. Cruz Hermética desenhada com 11 posições na sequência fornecida. Zoom/pan disponível para inspeção em telas pequenas.
- R2-04: Se sim / Se não, Quatro elementos e Cruz Hermética no catálogo, além dos modos anteriores. Quatro elementos: fogo/ação, água/emoções, ar/pensamento, terra/concretização; convenção de layout explicitada na UI, sem alegação de padrão universal.
- R2-05: opção de um arcano maior e um menor para cada posição de qualquer estrutura. Seleção manual de cada componente, sem substituição, filtragem obrigatória por componente. Configuração antes de retirar cartas.
- R2-06: seleção fechada distribuída, percorrer horizontalmente com anterior/próxima e escolher, filtros inteiro/maiores/menores; divisão em 2 ou 3 montes com cortes ajustáveis, escolha do monte, possibilidade de reunir começando pelo monte escolhido. Nunca revelar identidade antes da colocação e toque.
- R2-07: verso procedural próprio índigo/ameixa/latão, independente do antigo PNG. Mesma identidade em pilha, seleção e mesa.
- R2-08: mouse hover mostra painel flutuante contextual: posição, pergunta-guia, nome, palavras-chave e significado da carta revelada. Carta fechada mostra somente papel da posição. Touch/teclado têm acesso equivalente por toque/pressão longa/foco. Texto interpretativo orienta reflexão, sem inventar interpretação personalizada.
- R2-09: banner na tela da tiragem, faixa própria abaixo da mesa, sem cobertura das cartas ou intersticiais. Home sem banner. Sem ID configurado, sem banner fictício. Compra remove_ads preservada.

## Estratégia
Testes antes da alteração para persistência explícita, catálogo, pares, geometria e anúncio. Atualizar testes anteriores cujo contrato de autosave/grade foi revogado; manter cobertura de retirada, cancelamento, revelação, drag e privacidade. Validar Web real em retrato/paisagem com hover, seleção e salvamento/descartes. Build Android após os testes. Relatórios anteriores ficam históricos.

## Fechamento

Implementação validada pela suíte de 93 testes e pelo roteiro Web real. Evidências atuais e limites de publicação em docs/VALIDATION.md. APKs da revisão compilados com assinatura de desenvolvimento.
