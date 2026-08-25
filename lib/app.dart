import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'state/providers.dart';
import 'ui/shell/app_shell.dart';

/// Racine de l'application.
class LeveliaApp extends ConsumerWidget {
  const LeveliaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(appControllerProvider);

    // La préférence d'apparence vit dans les données : tant qu'elles ne sont
    // pas chargées, on suit le système.
    final modeTheme = etat.valueOrNull?.themeMode ?? ThemeMode.system;

    return MaterialApp(
      title: 'Levelia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: modeTheme,
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
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚔️', style: TextStyle(fontSize: 44)),
            SizedBox(height: 20),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(minHeight: 4),
            ),
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
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              Gaps.h16,
              const Text(
                'Impossible de charger tes données',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Gaps.h8,
              Text(message, textAlign: TextAlign.center),
              Gaps.h24,
              FilledButton(
                onPressed: () => ref.invalidate(appControllerProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
