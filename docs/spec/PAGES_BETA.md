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
- Gerar o worker do banco com as mesmas versões travadas no `pubspec.lock`.
- Confirmar salvamento e exclusão apenas depois da persistência do lote no IndexedDB. O teste de navegador deve salvar e recarregar imediatamente, sem atraso artificial para a gravação.

Build reproduzível: `bash tool/build_pages` com Flutter 3.47.2. A primeira carga deve estar online; o uso offline fica disponível após a instalação dos recursos.

## Compatibilidade de persistência

O teste sem COOP/COEP reproduziu a perda da última transação ao recarregar: o Drift 2.34.4 pulava o flush do IndexedDB enquanto seu indicador de transação ainda estava ativo, inclusive durante COMMIT. `AppDatabase.persistedTransaction` espera uma instrução sem alteração de dados após o término da transação, forçando a conclusão do flush antes da confirmação na interface. A correção cobre salvamento e exclusão; permanece o armazenamento local, sem servidor de dados.
