import 'package:flutter/material.dart';

import '../goals/goals_screen.dart';
import '../habits/habits_screen.dart';
import '../profile/profile_screen.dart';
import '../stats/stats_screen.dart';
import '../today/today_screen.dart';

/// Largeur à partir de laquelle on passe d'une barre du bas (mobile) à un rail
/// latéral (tablette et ordinateur).
const double kWideBreakpoint = 760;

/// Une destination de la navigation principale.
class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.builder);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

const List<_Destination> _destinations = [
  _Destination(
    'Aujourd\'hui',
    Icons.today_outlined,
    Icons.today,
    _buildToday,
  ),
  _Destination(
    'Habitudes',
    Icons.check_circle_outline,
    Icons.check_circle,
    _buildHabits,
  ),
  _Destination('Objectifs', Icons.flag_outlined, Icons.flag, _buildGoals),
  _Destination(
    'Progression',
    Icons.insights_outlined,
    Icons.insights,
    _buildStats,
  ),
  _Destination('Profil', Icons.person_outline, Icons.person, _buildProfile),
];

Widget _buildToday(BuildContext _) => const TodayScreen();
Widget _buildHabits(BuildContext _) => const HabitsScreen();
Widget _buildGoals(BuildContext _) => const GoalsScreen();
Widget _buildStats(BuildContext _) => const StatsScreen();
Widget _buildProfile(BuildContext _) => const ProfileScreen();

/// Coque de navigation, adaptative selon la largeur disponible.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.sizeOf(context).width >= kWideBreakpoint;

    // IndexedStack conserve l'état de chaque onglet (position de défilement,
    // filtres) quand on navigue de l'un à l'autre.
    final contenu = IndexedStack(
      index: _index,
      children: [
        for (final destination in _destinations)
          Builder(builder: destination.builder),
      ],
    );

    if (large) {
      return Scaffold(
        body: Row(
          children: [
            _SideRail(index: _index, onSelect: _select),
            const VerticalDivider(width: 1),
            Expanded(child: contenu),
          ],
        ),
      );
    }

    return Scaffold(
      body: contenu,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon, size: 22),
              selectedIcon: Icon(d.selectedIcon, size: 22),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

/// Rail latéral affiché sur grand écran, avec l'identité de l'app en tête.
class _SideRail extends StatelessWidget {
  const _SideRail({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationRail(
      selectedIndex: index,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      backgroundColor: theme.colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Text('⚔️', style: TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              'Levelia',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
      destinations: [
        for (final d in _destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
    );
  }
}
