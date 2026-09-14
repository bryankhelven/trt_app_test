# Monetização sem interromper leituras

Decisão de produto: o núcleo, as 78 cartas, todos os spreads, a biblioteca, o diário e a exportação continuam livres. Sem intersticiais, app-open ou vídeo rewarded. Nunca vender promessa de previsão nem pressionar o usuário durante uma leitura.

1. Banner discreto no rodapé da tela de tiragem, em faixa própria abaixo da mesa, condicionado ao consentimento e à ausência de remove_ads. Home sem banner. O pedido atual substitui a localização definida anteriormente.
2. Compra única remove_ads, com restauração em Configurações. Preço vem da loja; não há preço artificial fixado no app.
3. Possíveis expansões futuras: temas visuais, decks adicionais com licença e ferramentas de organização do diário. Não implementadas, não cobradas nesta versão.

## Ativação técnica após configuração das contas
Criar um produto não consumível `remove_ads` na loja, com applicationId/bundle ID definitivos. Substituir app ID de teste AdMob no AndroidManifest.xml e configurar mensagens de privacidade UMP. Exemplo de build sandbox:

```sh
tool/flutter build apk --dart-define=ENABLE_STORE=true --dart-define=REMOVE_ADS_PRODUCT=remove_ads --dart-define=ANDROID_BANNER_ID=SEU_ID_DE_BANNER
```

Não ativar cobrança de produção apenas com esse comando. Antes, validar: conta de teste licenciada; preço localizado; compra; cancelamento; compra pendente; evento duplicado; restauração em instalação limpa; falha de rede; persistência; estorno/revogação; verificação de recibos; consentimento e sua revisão. O adaptador atual confia nos eventos nativos e mantém entitlement local. Verificação criptográfica independente e reconciliação de revogação ainda precisam ser implementadas/validadas.

iOS possui adaptador de compra, mas publicidade está desativada. Windows/Linux/Web funcionam sem loja e sem anúncios. Na build padrão, tentar comprar informa indisponibilidade e nunca simula pagamento.

Fontes técnicas consultadas em 2026-09-14:
- https://pub.dev/packages/in_app_purchase
- https://pub.dev/packages/google_mobile_ads
- https://github.com/googleads/googleads-mobile-flutter/blob/main/samples/admob/banner_example/lib/main.dart

Nenhuma compra, criação de conta, upload de produto ou publicação foi realizada nesta tarefa.
