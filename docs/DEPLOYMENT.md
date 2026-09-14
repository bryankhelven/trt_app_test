# Publicação da beta web

- Conta: `bryankhelven` (ID 22553092).
- Repositório público: https://github.com/bryankhelven/trt_app_test
- Endereço: https://bryankhelven.github.io/trt_app_test/
- Código Flutter: `main`.
- Arquivos publicados: raiz de `gh-pages`, com `.nojekyll` e HTTPS.
- Primeira versão: fonte `201e484`; pacote `a547b63`; Arcanum 1.2.0+3.

O banco da beta fica no navegador, com nome próprio `arcanum_trt_app_test_beta`. O Pages serve os arquivos estáticos; não recebe perguntas, notas ou tiragens. Limpar os dados do site remove o diário local. Tiragens não salvas são descartadas ao sair/recarregar.

## Atualizar a publicação

Depois de alterar e enviar a fonte para `main`, execute `bash tool/build_pages` com Flutter 3.47.2. Isso gera o worker do banco usando as dependências travadas, compila para `/trt_app_test/`, prepara o cache offline e adiciona `.nojekyll`.

Em um checkout separado da branch `gh-pages`, substitua os arquivos do site pelo conteúdo de `build/web`, preservando `.git`. Faça commit e push nessa branch; o GitHub executará “pages build and deployment”. Não basta enviar alterações de Dart para `main`: a versão web precisa ser recompilada e enviada para `gh-pages`.

Antes de qualquer envio, confira `gh api user --jq .login`: deve retornar `bryankhelven`. Nesta publicação foi usado HTTPS com o helper de credenciais do `gh`, evitando a identidade SSH de outra conta.

## Verificação em 14/09/2026

- 108 testes Flutter passaram; análise estática sem apontamentos.
- Build Web concluído com base `/trt_app_test/` e recursos locais.
- Chromium, em servidor sem COOP/COEP: selecionar, arrastar, revelar, retirar/reencaixar, associar complementos, hover, salvar/reabrir, retrato/paisagem, maior+menor, cruzes e uso offline passaram, sem erros nos fluxos testados.
- Persistência confirmada com `sharedIndexedDb`: a tiragem salva sobrevive ao recarregamento imediato. A regressão reproduziu a falha antes da correção.
- Teste de atualização com duas versões: primeira instalação sem recarga; versão nova espera confirmação e preserva o rascunho; aceitar recarrega uma vez; cache de outro projeto preservado; nova versão abre offline.
- A mesma aceitação completa passou no endereço público HTTPS do Pages, sem erros nos fluxos testados. O pacote público corresponde ao build local, com cache `02994914f9831e657b6c`.
- No endereço público, salvar e excluir também sobreviveram ao recarregamento imediato no teste dedicado de persistência.
- Deploy do GitHub concluído com sucesso: https://github.com/bryankhelven/trt_app_test/actions/runs/34817892503

O teste de navegador está em `tool/web_revision3.py` e aceita `ARCANUM_PREVIEW_URL` (sem barra final) e `CHROME_EXECUTABLE`. O teste de atualização está em `tool/test_web_update.py`; o de salvar/excluir e recarregar está em `tool/test_web_persistence.py`. Todos usam Playwright Python. As capturas locais ficam fora do Git.
