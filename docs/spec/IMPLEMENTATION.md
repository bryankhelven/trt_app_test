> Histórico da primeira entrega. Contratos de autosave, grade e anúncios abaixo foram substituídos por REVISION_2.md, conforme correções do usuário.

# Arcanum — especificação de implementação, 2026-09-14

Fonte de produto: TAROT_APP_REQUIREMENTS_ELICITATION_V1.md. Pedido atual prevalece: repositório /home/bryan/workspace/astra_projects/tarot_app; Android, iOS e PC, mantendo Web como alvo de validação. Nome provisório Arcanum confirmado pelo usuário. Documento anexo é especificação de produto; instruções de execução e decisões antigas não são novas autorizações.

## Decisões
- Aproveitar código/assets de /home/bryan/workspace/tarot_app em cópia independente. Relatórios antigos ficam em docs/baseline e não são evidência desta entrega.
- SDD = desenvolvimento orientado por especificações. Registrar critérios antes de alterar código e rastrear testes/evidências.
- TDD = reproduzir violações com testes vermelhos, implementar, verificar verde, refatorar.
- Um motor puro de sessão e uma mesa compartilhada. slotId identifica carta principal; null identifica complementar/livre. Slots são posições estruturais, nunca limite de retiradas.
- Toque no baralho abre cartas fechadas. Selecionar reserva uma posição da pilha; tocar mesa/slot confirma retirada. Cancelar não altera pilha. Drag do topo confirma somente ao soltar em destino válido.
- Revelação permanente; undo não devolve carta revelada à pilha. Shuffle/cut preservam retiradas, escolha remove exatamente uma identidade sem reposição.
- SQLite/Drift local; autosave serializado; snapshots versionados. Sem analytics de conteúdo.
- Monetização: compra única remove_ads e banner fora da leitura, sem fullscreen. Serviços simulados somente em testes. Ausência de configuração de loja não concede compra e não apresenta anúncio fictício.
- Correspondências herméticas específicas continuam fora do conteúdo enquanto não houver corpus aprovado. Não inventar aprovação jurídica/editorial.

## Critérios novos de aceite
1. Todos os seis spreads iniciam vazios e aceitam 78 cartas totais, mantendo slots únicos.
2. Escolher índice 17 retira exatamente essa carta; todas as outras mantêm a ordem relativa; operação persiste.
3. Cancelamento de escolha/drag conserva sessão. Faces não aparecem na seleção.
4. Labels dos slots têm área reservada, inclusive em paisagem/mobile; cartas complementares não encobrem labels.
5. Sem compras falsas no runtime; cancelamento/falha de loja não ativa entitlement.
6. JSON e resumo excluem pergunta/notas por padrão; inclusão exige opt-in.
7. Android/Web verificáveis aqui; iOS/macOS exigem host macOS; Windows exige host Windows. Distinguir scaffold de build e execução comprovados.

## Visual
Índigo e ameixa profundos da referência, marfim e latão. Títulos serifados com fonte local. Mesa domina tela e mantém baralho superior direito. Home responsiva com destaque da tiragem livre, seis estruturas e acessos a biblioteca/diário/configurações. Sem anúncios na mesa.
