import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../work/presentation/screens/projects_screen.dart';
import '../../../ideas/presentation/screens/ideas_screen.dart';
import '../../../health/presentation/screens/habits_screen.dart';
import '../../../family/presentation/screens/family_dashboard_screen.dart';

/// Combined Work tab: Projects + Ideas behind a segmented toggle.
class WorkHubScreen extends StatefulWidget {
  const WorkHubScreen({super.key});

  @override
  State<WorkHubScreen> createState() => _WorkHubScreenState();
}

class _WorkHubScreenState extends State<WorkHubScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.background,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedToggle(
                labels: const ['Projects', 'Ideas'],
                icons: const [Icons.folder_outlined, Icons.lightbulb_outline_rounded],
                selected: _selected,
                onChanged: (i) => setState(() => _selected = i),
                activeColor: AppColors.workColor,
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selected,
            children: const [ProjectsScreen(), IdeasScreen()],
          ),
        ),
      ],
    );
  }
}

/// Combined Life tab: Habits + Family behind a segmented toggle.
class LifeHubScreen extends StatefulWidget {
  const LifeHubScreen({super.key});

  @override
  State<LifeHubScreen> createState() => _LifeHubScreenState();
}

class _LifeHubScreenState extends State<LifeHubScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.background,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedToggle(
                labels: const ['Habits', 'Family'],
                icons: const [Icons.spa_outlined, Icons.favorite_border_rounded],
                selected: _selected,
                onChanged: (i) => setState(() => _selected = i),
                activeColor: AppColors.healthColor,
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selected,
            children: const [HabitsScreen(), FamilyDashboardScreen()],
          ),
        ),
      ],
    );
  }
}

/// Reusable segmented toggle matching the dark premium aesthetic.
class SegmentedToggle extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int selected;
  final ValueChanged<int> onChanged;
  final Color activeColor;

  const SegmentedToggle({
    super.key,
    required this.labels,
    required this.icons,
    required this.selected,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive ? activeColor.withAlpha(35) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive
                      ? Border.all(color: activeColor.withAlpha(70))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[i],
                      size: 15,
                      color: isActive ? activeColor : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        color: isActive ? activeColor : AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
