import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_controller.dart';

/// App version shown in Settings/About; keep in sync with pubspec.yaml's
/// `version:` field (no `package_info_plus` dependency needed for a single
/// static value in v1).
const appVersion = '1.0.0+1';

/// Settings screen (M9): theme, sound/haptics/reduced-motion preferences,
/// deck/licenses credits, privacy notice, app version, restore purchases
/// and the one-time `remove_ads` entitlement. Deliberately has no
/// reversed-cards toggle (hard domain rule, see DR-005). Sound and haptics
/// toggles persist a preference only — no actual sound/haptic feedback is
/// wired into gameplay yet (v1 scope; see KNOWN_LIMITATIONS.md).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Não foi possível carregar as configurações.'),
        ),
        data: (state) => ListView(
          children: [
            const _SectionHeader('Aparência'),
            RadioGroup<ThemeMode>(
              groupValue: state.themeMode,
              onChanged: (v) => controller.setThemeMode(v!),
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    key: Key('theme-system'),
                    title: Text('Padrão do sistema'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    key: Key('theme-light'),
                    title: Text('Claro'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    key: Key('theme-dark'),
                    title: Text('Escuro'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
            SwitchListTile(
              key: const Key('reduced-motion-switch'),
              title: const Text('Reduzir animações'),
              subtitle: const Text(
                'Desativa transições não essenciais entre telas.',
              ),
              value: state.reducedMotion,
              onChanged: controller.setReducedMotion,
            ),
            const Divider(),
            const _SectionHeader('Privacidade'),
            const ListTile(
              title: Text('Suas perguntas e notas'),
              subtitle: Text(
                'Ficam apenas neste dispositivo. Nunca são enviadas para '
                'análise, anúncios ou qualquer serviço externo.',
              ),
            ),
            const Divider(),
            const _SectionHeader('Baralho e créditos'),
            const ListTile(
              key: Key('deck-credits'),
              title: Text('Rider-Waite-Smith (1909)'),
              subtitle: Text(
                'Arte de Pamela Colman Smith, publicada por Rider & Son — '
                'reproduções de domínio público via Wikimedia Commons. '
                'Ilustrações históricas de 1909. Texto de apoio em português, '
                'sem interpretação automática da sua leitura.',
              ),
            ),
            ListTile(
              key: const Key('open-licenses'),
              leading: const Icon(Icons.description_outlined),
              title: const Text('Licenças de bibliotecas de terceiros'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Arcanum',
                applicationVersion: appVersion,
              ),
            ),
            const Divider(),
            const _SectionHeader('Compras'),
            if (state.removeAdsEntitled)
              const ListTile(
                key: Key('remove-ads-active'),
                leading: Icon(Icons.check_circle_outline),
                title: Text('Anúncios removidos'),
                subtitle: Text('Obrigado por apoiar o app.'),
              )
            else
              ListTile(
                key: const Key('remove-ads-purchase'),
                leading: const Icon(Icons.block),
                title: const Text('Remover anúncios'),
                subtitle: const Text('Compra única.'),
                onTap: () async {
                  bool purchased;
                  try {
                    purchased = await controller.purchaseRemoveAds();
                  } on Object {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Compras indisponíveis nesta versão. Nenhuma cobrança foi feita.',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          purchased
                              ? 'Anúncios removidos.'
                              : 'Compra não concluída.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ListTile(
              key: const Key('restore-purchases'),
              leading: const Icon(Icons.restore),
              title: const Text('Restaurar compras'),
              onTap: () async {
                int count;
                try {
                  count = await controller.restorePurchases();
                } on Object {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Loja indisponível. Tente novamente quando estiver conectado.',
                        ),
                      ),
                    );
                  }
                  return;
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count > 0
                            ? 'Compras restauradas.'
                            : 'Nenhuma compra encontrada para restaurar.',
                      ),
                    ),
                  );
                }
              },
            ),
            const Divider(),
            const ListTile(
              title: Text('Versão do app'),
              subtitle: Text(appVersion),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
