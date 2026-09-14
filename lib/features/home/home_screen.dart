import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/spreads/spread_catalog.dart';
import '../../app/providers.dart';

final recentReadingsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(readingRepositoryProvider).list(),
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recent = ref.watch(recentReadingsProvider).value ?? [];
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(.7, -.6),
            radius: 1.4,
            colors: [
              scheme.primaryContainer.withValues(alpha: .65),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_outlined,
                                color: scheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'ARCANUM',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(letterSpacing: 5),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Configurações',
                                onPressed: () => context.push('/settings'),
                                icon: const Icon(Icons.tune),
                              ),
                            ],
                          ),
                          const SizedBox(height: 44),
                          Text(
                            'UM TEMPO PARA OLHAR PARA DENTRO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 2,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'As cartas. O silêncio.\nSeu próprio caminho.',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontSize: 46,
                              height: 1.04,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Um espaço para contemplar.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Material(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              key: const Key('start-free'),
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => context.go('/reading/free'),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    const _DeckIllustration(),
                                    const SizedBox(width: 28),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tiragem Livre',
                                            style:
                                                theme.textTheme.headlineMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Sua intuição conduz a mesa. Escolha, revele e encontre suas conexões.',
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'ABRIR A MESA',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  color: scheme.primary,
                                                  letterSpacing: 1.5,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Uma estrutura para sua pergunta',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Escolha cada carta no seu tempo. Há sempre espaço para ir além.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth > 780
                                  ? 3
                                  : constraints.maxWidth > 520
                                  ? 2
                                  : 1;
                              final tileWidth =
                                  (constraints.maxWidth - (columns - 1) * 12) /
                                  columns;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final mode in SpreadCatalog.modes.where(
                                    (m) => m.spread != null,
                                  ))
                                    SizedBox(
                                      width: tileWidth,
                                      child: _ModeTile(mode: mode),
                                    ),
                                ],
                              );
                            },
                          ),
                          if (recent.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            Text(
                              'Seu último encontro',
                              style: theme.textTheme.headlineSmall,
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.history),
                              title: Text(
                                'Consultar ${SpreadCatalog.byId(recent.first.spreadId).name}',
                              ),
                              subtitle: Text(
                                '${recent.first.placed.length} cartas · salvas neste dispositivo',
                              ),
                              trailing: const Icon(Icons.arrow_forward),
                              onTap: () => context.push(
                                '/journal/${recent.first.readingId}',
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          const Divider(),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: () => context.push('/library'),
                                icon: const Icon(Icons.menu_book_outlined),
                                label: const Text('Biblioteca de cartas'),
                              ),
                              TextButton.icon(
                                onPressed: () => context.push('/journal'),
                                icon: const Icon(Icons.auto_stories_outlined),
                                label: const Text('Diário de leituras'),
                              ),
                              TextButton.icon(
                                onPressed: () => context.push('/settings'),
                                icon: const Icon(Icons.settings_outlined),
                                label: const Text('Configurações'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '78 cartas · leituras privadas · seu ritmo',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode});
  final ReadingMode mode;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: .65),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/reading/spread/${mode.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.style_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const Spacer(),
                  Text(mode.cardCountLabel, style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 14),
              Text(mode.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                mode.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckIllustration extends StatelessWidget {
  const _DeckIllustration();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 64,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final angle in [-.16, .12, 0.0])
            Transform.rotate(
              angle: angle,
              child: Container(
                width: 58,
                height: 98,
                decoration: BoxDecoration(
                  color: const Color(0xFF251C39),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFCAB78A)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFCAB78A),
                    size: 26,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
