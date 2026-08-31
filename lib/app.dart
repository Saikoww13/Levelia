import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'domain/models/app_data.dart';
import 'state/providers.dart';
import 'ui/shell/app_shell.dart';

/// Racine de l'application.
class LeveliaApp extends ConsumerWidget {
  const LeveliaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(appControllerProvider);

    // La préférence d'apparence vit dans les données : tant qu'elles ne sont
    // pas chargées, on suit le système. `null` laisse Cupertino se caler sur
    // le réglage de l'appareil, comme le fait une application iOS native.
    final mode = etat.valueOrNull?.themeMode ?? AppearanceMode.system;
    final luminosite = switch (mode) {
      AppearanceMode.system => null,
      AppearanceMode.light => Brightness.light,
      AppearanceMode.dark => Brightness.dark,
    };

    return CupertinoApp(
      title: 'Levelia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(luminosite),
      home: etat.when(
        data: (_) => const AppShell(),
        loading: () => const _BootScreen(),
        error: (erreur, _) => _ErrorScreen(message: '$erreur'),
      ),
    );
  }
}

/// Écran affiché le temps de relire les données locales.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚔️', style: AppText.emoji(44)),
            const SizedBox(height: 24),
            const CupertinoActivityIndicator(radius: 12),
          ],
        ),
      ),
    );
  }
}

/// Affiché si les données locales sont illisibles au point de bloquer le démarrage.
class _ErrorScreen extends ConsumerWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = CupertinoDynamicColor.resolve(AppTheme.label, context);
    final secondaire = CupertinoDynamicColor.resolve(
      AppTheme.secondaryLabel,
      context,
    );

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 44,
                    color: AppTheme.missed,
                  ),
                  Gaps.h16,
                  Text(
                    'Impossible de charger tes données',
                    textAlign: TextAlign.center,
                    style: AppText.title(label, size: 18),
                  ),
                  Gaps.h8,
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppText.caption(secondaire),
                  ),
                  Gaps.h24,
                  CupertinoButton.filled(
                    onPressed: () => ref.invalidate(appControllerProvider),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
