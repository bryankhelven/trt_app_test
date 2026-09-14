# Beta web no GitHub Pages

Solicitação: publicar o Arcanum na conta `bryankhelven`, repositório `trt_app_test`, para beta testers.

- Código Flutter na branch `main`; pacote web compilado na branch `gh-pages`.
- URL esperada: https://bryankhelven.github.io/trt_app_test/.
- Build usa base `/trt_app_test/` e recursos locais, incluindo SQLite/WASM.
- Validar abertura e diário persistente sem COOP/COEP, como no GitHub Pages.
- Leituras e notas ficam no navegador do beta tester. Salvar continua sendo uma ação explícita.
- Atualizações oferecem um botão e não recarregam uma tiragem em andamento sem ação da pessoa.
- Cache offline isolado ao caminho deste site, sem remover caches de outros projetos da conta.
- Repositório público com código e assets necessários; sem SDKs locais, credenciais, APKs ou capturas de testes.

Build reproduzível: `bash tool/build_pages` com Flutter 3.47.2. A primeira carga deve estar online; o uso offline fica disponível após a instalação dos recursos.
