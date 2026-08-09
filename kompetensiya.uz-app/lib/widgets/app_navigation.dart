import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _TabSpec {
  final String label;
  final String iconName;
  final int branchIndex;

  const _TabSpec({
    required this.label,
    required this.iconName,
    required this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  static const List<_TabSpec> _tabs = [
    _TabSpec(label: 'Bosh sahifa', iconName: 'home', branchIndex: 0),
    _TabSpec(label: 'Baholash', iconName: 'assessment', branchIndex: 1),
    _TabSpec(label: 'Vakansiyalar', iconName: 'work', branchIndex: 2),
    _TabSpec(label: 'Hamjamiyat', iconName: 'groups', branchIndex: 3),
    _TabSpec(label: 'Profil', iconName: 'person', branchIndex: 4),
  ];

  void _onTabTap(int visualIndex) {
    final spec = _tabs[visualIndex];
    widget.navigationShell.goBranch(
      spec.branchIndex,
      initialLocation: spec.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  int get _selectedVisualIndex {
    final currentBranch = widget.navigationShell.currentIndex;
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].branchIndex == currentBranch) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final selectedIndex = _selectedVisualIndex;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding + 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(46),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final isActive = i == selectedIndex;

            return GestureDetector(
              onTap: () => _onTabTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withAlpha(38)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavIcon(iconName: tab.iconName, isActive: isActive),
                    if (isActive) ...[
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String iconName;
  final bool isActive;

  const _NavIcon({required this.iconName, required this.isActive});

  IconData _resolveIcon(String name) {
    switch (name) {
      case 'home':
        return isActive ? Icons.home_rounded : Icons.home_outlined;
      case 'school':
        return isActive ? Icons.school_rounded : Icons.school_outlined;
      case 'assessment':
        return isActive
            ? Icons.assignment_turned_in_rounded
            : Icons.assignment_outlined;
      case 'work':
        return isActive ? Icons.work_rounded : Icons.work_outline_rounded;
      case 'groups':
        return isActive ? Icons.groups_rounded : Icons.groups_outlined;
      case 'attendance':
        return isActive ? Icons.fact_check_rounded : Icons.fact_check_outlined;
      case 'person':
        return isActive ? Icons.person_rounded : Icons.person_outline_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        _resolveIcon(iconName),
        key: ValueKey('$iconName-$isActive'),
        color: isActive ? Colors.white : Colors.white54,
        size: 22,
      ),
    );
  }
}
