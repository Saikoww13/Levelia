import 'package:flutter/material.dart';

/// Ouvre une feuille modale au format standard de l'application.
///
/// Le même composant sert sur mobile et sur ordinateur : la feuille monte
/// depuis le bas, mais sa largeur est bornée pour rester lisible sur un grand
/// écran. Le contenu défile et se décale au-dessus du clavier.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (contexte) => _SheetFrame(title: title, child: builder(contexte)),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clavier = MediaQuery.viewInsetsOf(context).bottom;
    final hauteurMax = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: hauteurMax),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + clavier),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
