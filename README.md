# Arcanum

## Beta para testes

**Abrir:** https://bryankhelven.github.io/trt_app_test/

Use pelo navegador do celular ou computador. As tiragens só entram no diário quando você toca em **Salvar tiragem**; o diário pertence àquele navegador/dispositivo. Para relatar problemas, use [Issues](https://github.com/bryankhelven/trt_app_test/issues/new/choose), informando o navegador, aparelho e os passos para reproduzir.

Esta beta web não exige login e não realiza cobranças. Atualizações mostram um botão para que você salve sua tiragem antes de recarregar. Depois da primeira carga completa, o app também pode abrir offline.

O código está em `main` e o pacote publicado em `gh-pages`. Para gerar o pacote do Pages, execute `bash tool/build_pages` (Flutter 3.47.2). O build usa `/trt_app_test/` como caminho base e um banco local específico para a beta. O Pages publica a raiz da branch `gh-pages`.

Consulte [publicação e verificações da beta](docs/DEPLOYMENT.md) para atualizar o site.

App Flutter de tarot com baralho físico como referência: você escolhe, coloca e revela cada carta. Android, iOS e desktop; Web como alvo adicional. Nome e ícone provisórios.

## Experiência revisada (1.2.0+3)

- 78 cartas RWS locais, textos PT-BR, biblioteca e busca.
- Dez modos: Livre, Carta Única, Se sim / Se não, Passado/Presente/Futuro, Situação/Obstáculo/Conselho, Relação, Ferradura, Cruz Celta, Cruz Hermética e Quatro elementos.
- Mesa em retrato e paisagem com geometria das tiragens preservada, Cruz Celta transversal, cruz hermética de 11 posições, ajuste por largura/altura, ampliação e movimentação da mesa ampliada.
- Animações de retirada, chegada, encaixe/movimento e revelação, respeitando movimento reduzido no app e no sistema.
- Verso próprio em índigo/ameixa/latão. Hover ou pressão longa para consultar carta e posição; toque em carta revelada abre os detalhes com a pergunta-guia da posição.
- Escolha fechada distribuída ou percorrendo cartas; filtros inteiro/maiores/menores. Divisão em 2 ou 3 montes com cortes ajustáveis e reunião a partir do monte escolhido.
- Em Opções da mesa, antes de retirar cartas: **Usar maior + menor por posição**. Cada posição exige um de cada, escolhido manualmente. Opção disponível em todas as nove estruturas.
- Cartas principais podem sair para a área livre e voltar a qualquer posição vazia. Não aparecem espaços antecipados de complemento: soltar junto de uma carta principal já encaixada ou sobre ela faz o complemento aparecer, sem substituir a principal. Complementos são numerados pela ordem de associação em cada posição; pares maior+menor compartilham a sequência. Cartas livres usam “Carta X”, pela ordem de retirada. Todas as estruturas permitem retirar até as 78 cartas. Nenhuma distribuição automática ou retirada com reposição. A carta transversal da Cruz Celta é uma convenção de disposição, não um significado invertido.
- **Salvar tiragem é explícito.** A sessão começa só na memória. Notas, revelações e movimentos não gravam automaticamente. Sair da mesa, iniciar outra ou fechar/recarregar o processo descarta alterações não salvas. Segundo plano e rotação conservam a memória enquanto o processo existir. Salvar novamente atualiza o snapshot; Nova tiragem não apaga snapshots anteriores.
- Diário permite **Abrir tiragem na mesa**. O que foi salvo pode ser consultado e alterado, com novo salvamento explícito. Dados persistidos pela versão anterior foram preservados, sem exclusão automática retroativa.
- Banner Android configurável na faixa abaixo da mesa, sem cobrir cartas; Home sem anúncios. Compra única remove_ads preparada. Builds padrão não exibem anúncios fictícios nem simulam compras.

As especificações vigentes são `docs/spec/REVISION_2.md` e `docs/spec/REVISION_3.md`; a revisão 3 substitui as antigas restrições de movimento. O pedido atual prevalece sobre contratos antigos de autosave, anúncios e grade.

## Executar neste computador

A pasta solicitada é `/home/bryan/workspace/astra_projects/tarot_app`. Flutter 3.47.2 / Dart 3.13.2 está em `.tooling/flutter`, isolado do projeto anterior. Dependências resolvidas estão fixadas em `pubspec.lock`.

```sh
cd ~/workspace/astra_projects/tarot_app
tool/flutter pub get
tool/build_web
python3 tool/serve_web.py
```

Abrir http://localhost:8878. A prévia desta revisão está em http://localhost:8879 para evitar o cache da prévia anterior; para servi-la manualmente, use `python3 tool/serve_web.py --port 8879`. O servidor envia COOP/COEP para persistência OPFS. O build inclui os recursos essenciais e um único service worker offline. Na primeira abertura é necessário carregar esses recursos; as próximas aberturas funcionam offline após a instalação do cache.

Android neste WSL:

```sh
source tool/android_env.sh
tool/flutter build apk --debug
# Com dispositivo Android ou emulador disponível:
tool/flutter run -d ID_DO_DISPOSITIVO
```

APK ARM64: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`. Versão e hashes da revisão em `docs/evidence/revision3/android-artifacts.json`.

O APK desse comando é `build/app/outputs/flutter-apk/app-debug.apk`. A compilação otimizada usa `tool/flutter build apk --release --split-per-abi` e gera um APK por arquitetura. Todos usam identificação e assinatura de desenvolvimento nesta entrega. Não enviar à loja como release final. O teste de integração pode substituir o APK debug por um executável de testes; gere novamente o alvo padrão antes de compartilhar esse arquivo.

Em outro ambiente, instalar Flutter 3.47.2 e executar os comandos Flutter usuais na raiz. No macOS: `flutter build ios --no-codesign` / `flutter run -d macos`. No Windows: `flutter build windows`. No Linux com GTK/clang/ninja: `flutter build linux`. Android requer JDK e Android SDK. iOS exige macOS/Xcode; Windows nativo exige Windows e Visual Studio com ferramentas C++.

## Testes e especificações

```sh
tool/flutter test
tool/flutter analyze
tool/check
# Em dispositivo ou emulador:
tool/flutter test integration_test/free_reading_test.dart -d ID_DO_DISPOSITIVO
# Com Playwright Python instalado e servidor Web já iniciado:
python tool/web_revision3.py
```

O teste Web aceita `CHROME_EXECUTABLE`. Para instalar as dependências do smoke em ambiente próprio: `python -m pip install playwright` e `python -m playwright install chromium`.

- `TAROT_APP_REQUIREMENTS_ELICITATION_V1.md`: documento original preservado.
- `docs/spec/REVISION_2.md`: especificação atual e critérios R2-01 a R2-09.
- `docs/spec/IMPLEMENTATION.md`: decisões históricas da primeira implementação, parcialmente revogadas.
- `docs/ARCHITECTURE.md`: domínio, persistência, interface e plataformas.
- `docs/TRACEABILITY.md`: requisitos e cobertura.
- `docs/VALIDATION.md`: evidências e limitações atuais.
- `docs/MONETIZATION.md`: modelo comercial e ativação de loja.
- `docs/evidence/`: resultados reais desta execução; logs red/green e capturas. Evidências atuais em `docs/evidence/revision2/`.
- `docs/baseline/`: referência visual e relatórios herdados, que não provam o estado atual.

## Antes de publicar nas lojas

Configurar identidade definitiva, assinatura, contas/produtos e preço nas lojas; verificar recibos e estornos; validar billing/consentimento em sandbox; revisar conteúdo e proveniência jurídica; testar iOS/Windows em seus hosts. Consulte a lista completa em `docs/VALIDATION.md`. A beta web é independente dessas publicações nas lojas.
