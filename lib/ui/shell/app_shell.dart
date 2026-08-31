import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../goals/goals_screen.dart';
import '../habits/habits_screen.dart';
import '../profile/profile_screen.dart';
import '../stats/stats_screen.dart';
import '../today/today_screen.dart';

/// Largeur à partir de laquelle on passe de la barre d'onglets (iPhone) à une
/// barre latérale (iPad en paysage, Mac).
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
    CupertinoIcons.square_list,
    CupertinoIcons.square_list_fill,
    _buildToday,
  ),
  _Destination(
    'Habitudes',
    CupertinoIcons.checkmark_circle,
    CupertinoIcons.checkmark_circle_fill,
    _buildHabits,
  ),
  _Destination(
    'Objectifs',
    CupertinoIcons.flag,
    CupertinoIcons.flag_fill,
    _buildGoals,
  ),
  _Destination(
    'Progression',
    CupertinoIcons.chart_bar,
    CupertinoIcons.chart_bar_fill,
    _buildStats,
  ),
  _Destination(
    'Profil',
    CupertinoIcons.person,
    CupertinoIcons.person_fill,
    _buildProfile,
  ),
];

Widget _buildToday(BuildContext _) => const TodayScreen();
Widget _buildHabits(BuildContext _) => const HabitsScreen();
Widget _buildGoals(BuildContext _) => const GoalsScreen();
Widget _buildStats(BuildContext _) => const StatsScreen();
Widget _buildProfile(BuildContext _) => const ProfileScreen();

/// Coque de navigation, adaptative selon la largeur disponible.
///
/// Sur iPhone, la barre d'onglets Cupertino en bas. Sur iPad et Mac, une barre
/// latérale : Apple ne descend pas les onglets en bas d'une grande fenêtre.
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
    final c = AppColors.of(context);
    final large = MediaQuery.sizeOf(context).width >= kWideBreakpoint;

    if (large) {
      return CupertinoPageScaffold(
        child: Row(
          children: [
            _Sidebar(index: _index, onSelect: _select),
            Container(width: 1, color: c.separator),
            // IndexedStack conserve l'état de chaque onglet (défilement,
            // filtres) quand on passe de l'un à l'autre.
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  for (final d in _destinations) Builder(builder: d.builder),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // CupertinoTabScaffold donne à chaque onglet son propre navigateur et
    // conserve son état, exactement comme une application iOS à onglets.
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _index,
        onTap: _select,
        backgroundColor: c.bar,
        activeColor: AppTheme.seed,
        inactiveColor: c.secondary,
        border: Border(top: BorderSide(color: c.separator, width: 0.5)),
        items: [
          for (final d in _destinations)
            BottomNavigationBarItem(
              icon: Icon(d.icon, size: 24),
              activeIcon: Icon(d.selectedIcon, size: 24),
              label: d.label,
            ),
        ],
      ),
      tabBuilder: (context, index) =>
          CupertinoTabView(builder: _destinations[index].builder),
    );
  }
}

/// Barre latérale des grands écrans, dans l'esprit des colonnes d'iPadOS.
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final label = c.label;
    final secondaire = c.secondary;

    return Container(
      width: 232,
      color: c.bar,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Text('⚔️', style: AppText.emoji(22)),
                  Gaps.w8,
                  Text('Levelia', style: AppText.title(label, size: 19)),
                ],
              ),
            ),
            for (var i = 0; i < _destinations.length; i++)
              _SidebarItem(
                destination: _destinations[i],
                selected: i == index,
                onTap: () => onSelect(i),
                label: label,
                secondary: secondaire,
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.label,
    required this.secondary,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;
  final Color label;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final teinte = selected ? AppTheme.seed : secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.seed.withValues(alpha: 0.14)
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 20,
                color: teinte,
              ),
              Gaps.w12,
              Expanded(
                child: Text(
                  destination.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'CupertinoSystemText',
                    fontSize: 15,
                    letterSpacing: -0.2,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? label : secondary,
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
