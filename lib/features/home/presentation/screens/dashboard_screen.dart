import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/locale_service.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../../core/utils/stats_calculator.dart';
import '../../../dashboard/presentation/viewmodels/dashboard_view_model.dart';
import '../../../finance/presentation/screens/finance_dashboard_screen.dart';
import '../../../gamification/presentation/viewmodels/gamification_viewmodel.dart';
import '../../../gamification/presentation/screens/gamification_dashboard_screen.dart';
import '../../../gamification/domain/models/user_progress.dart';
import '../../../work/presentation/screens/standup_screen.dart';
import '../../../family/presentation/screens/contacts_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../settings/presentation/screens/calendar_screen.dart';
import 'work_hub_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = StorageService();
  int _currentIndex = 0;

  static const List<Widget> _staticScreens = [
    WorkHubScreen(),     // index 1: Projects + Ideas
    LifeHubScreen(),     // index 2: Habits + Family
    FinanceDashboardScreen(), // index 3: Finance
    CalendarScreen(),    // index 4: Calendar
  ];

  void _navigate(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final homeTab = _HomeTab(
      storage: _storage,
      digest: vm.digest,
      digestLoading: vm.digestLoading,
      onRefreshDigest: vm.refresh,
      onNavigate: _navigate,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [homeTab, ..._staticScreens],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final StorageService storage;
  final String digest;
  final bool digestLoading;
  final VoidCallback onRefreshDigest;
  final Function(int) onNavigate;

  const _HomeTab({
    required this.storage,
    required this.digest,
    required this.digestLoading,
    required this.onRefreshDigest,
    required this.onNavigate,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = ls.t('good_morning');
    } else if (hour < 17) {
      greeting = ls.t('good_afternoon');
    } else {
      greeting = ls.t('good_evening');
    }

    final gamVm = context.watch<GamificationViewModel>();
    final storage = widget.storage;
    final stats = StatsCalculator.calculate(
      projects: storage.getProjects(),
      habits: storage.getHabits(),
      transactions: storage.getTransactions(),
      ideas: storage.getIdeas(),
      contacts: storage.getContacts(),
    );
    final openTasks = stats.openTasks;
    final habitStreak = stats.habitStreak;
    final habitsToday = stats.habitsToday;
    final habits = storage.getHabits();
    final balance = stats.balance;
    final upcomingBdays = stats.upcomingBirthdays;
    final ideas = stats.activeIdeas;

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.background,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, ${storage.userName.isEmpty ? 'Chief' : storage.userName} 👋',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                DateFormat('EEEE, MMMM d').format(now),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── AI Daily Digest ──────────────────────────────────
              _DigestCard(
                digest: widget.digest,
                loading: widget.digestLoading,
                onRefresh: widget.onRefreshDigest,
                hasApiKey: storage.apiKey.isNotEmpty,
              ),
              const SizedBox(height: 16),

              // ── Quick Stats ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _QuickStatCard(
                      label: ls.t('open_tasks'),
                      value: openTasks.toString(),
                      icon: Icons.check_box_outlined,
                      color: AppColors.workColor,
                      onTap: () => widget.onNavigate(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickStatCard(
                      label: ls.t('habit_streak'),
                      value: '${habitStreak}d',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.healthColor,
                      onTap: () => widget.onNavigate(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickStatCard(
                      label: ls.t('balance'),
                      value: '\$${balance.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.financeColor,
                      onTap: () => widget.onNavigate(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Progress & Gamification ────────────────────────
              _ProgressCard(gamVm: gamVm),
              const SizedBox(height: 16),

              // ── Today's Habits ───────────────────────────────────
              if (habits.isNotEmpty) ...[
                SectionCard(
                  child: Column(
                    children: [
                      ModuleHeader(
                        title: ls.t('todays_habits'),
                        color: AppColors.healthColor,
                        icon: Icons.spa_outlined,
                        onAction: () => widget.onNavigate(2),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '$habitsToday/${habits.length}',
                            style: TextStyle(
                              color: habitsToday == habits.length
                                  ? AppColors.healthColor
                                  : AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ls.t('completed'),
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          if (habitsToday == habits.length)
                            Text(ls.t('perfect_day'), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: habits.isEmpty ? 0 : habitsToday / habits.length,
                          backgroundColor: AppColors.healthColor.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation(AppColors.healthColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Active Ideas ─────────────────────────────────────
              SectionCard(
                onTap: () => widget.onNavigate(1),
                child: Column(
                  children: [
                    ModuleHeader(
                      title: ls.t('active_ideas'),
                      color: AppColors.ideasColor,
                      icon: Icons.lightbulb_outline_rounded,
                      onAction: () => widget.onNavigate(1),
                      actionLabel: '+ Add',
                    ),
                    const SizedBox(height: 12),
                    if (ideas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          ls.t('no_active_ideas'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      )
                    else
                      ...ideas.map((idea) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.ideasColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    idea.title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          )),
                    Row(
                      children: List.generate(3, (i) {
                        final filled = i < ideas.length;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: i < 2 ? 6 : 0, top: 8),
                            height: 3,
                            decoration: BoxDecoration(
                              color: filled
                                  ? AppColors.ideasColor
                                  : AppColors.ideasColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ls.t('idea_slots_used', {'n': ideas.length.toString()}),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Daily Standup ────────────────────────────────────
              GradientCard(
                colors: const [Color(0xFF7C3AED), Color(0xFFDB2777)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StandupScreen()),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ls.t('daily_ai_standup'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ls.t('standup_subtitle'),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Upcoming Birthdays ───────────────────────────────
              if (upcomingBdays.isNotEmpty) ...[
                SectionCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactsScreen()),
                  ),
                  child: Column(
                    children: [
                      ModuleHeader(
                        title: ls.t('upcoming_birthdays'),
                        color: AppColors.accentRed,
                        icon: Icons.cake_outlined,
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContactsScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...upcomingBdays.take(3).map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(c.emoji, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.daysUntilBirthday == 0
                                        ? AppColors.accentRed.withOpacity(0.2)
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c.daysUntilBirthday == 0
                                        ? ls.t('today_birthday')
                                        : 'in ${c.daysUntilBirthday}d',
                                    style: TextStyle(
                                      color: c.daysUntilBirthday == 0
                                          ? AppColors.accentRed
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final GamificationViewModel gamVm;
  const _ProgressCard({required this.gamVm});

  @override
  Widget build(BuildContext context) {
    final progress = gamVm.progress;
    final score = gamVm.todayScoreValue;
    final activeStreaks = gamVm.activeStreaks;
    final missions = gamVm.todayMissions;
    final completed = gamVm.missionsCompletedCount;
    final total = gamVm.totalMissionsCount;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GamificationDashboardScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1030), Color(0xFF0D1117)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: level + score
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${progress.level} · ${progress.levelTitle}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${progress.xpInCurrentLevel} / ${UserProgress.xpPerLevel} XP',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Today's score circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _scoreColor(score).withOpacity(0.25),
                        _scoreColor(score).withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                        color: _scoreColor(score).withOpacity(0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        color: _scoreColor(score),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // XP progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.levelProgress,
                backgroundColor: AppColors.accent.withOpacity(0.12),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 14),

            // Streaks + Missions row
            Row(
              children: [
                // Active streaks
                if (activeStreaks.isNotEmpty) ...[
                  ...activeStreaks.take(3).map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s.flameEmoji,
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                '${s.currentStreak}d',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
                const Spacer(),
                // Missions counter
                if (total > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: completed == total
                          ? AppColors.accentGreen.withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          completed == total
                              ? Icons.check_circle_rounded
                              : Icons.flag_rounded,
                          size: 14,
                          color: completed == total
                              ? AppColors.accentGreen
                              : AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completed/$total missions',
                          style: TextStyle(
                            color: completed == total
                                ? AppColors.accentGreen
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Pending missions preview
            if (missions.where((m) => !m.isCompleted).isNotEmpty) ...[
              const SizedBox(height: 10),
              ...missions
                  .where((m) => !m.isCompleted)
                  .take(2)
                  .map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(m.difficultyEmoji,
                                style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                m.title,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '+${m.xpReward} XP',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 50) return AppColors.accent;
    if (score >= 25) return const Color(0xFFF59E0B);
    return AppColors.accentRed;
  }
}

class _DigestCard extends StatelessWidget {
  final String digest;
  final bool loading;
  final VoidCallback onRefresh;
  final bool hasApiKey;

  const _DigestCard({
    required this.digest,
    required this.loading,
    required this.onRefresh,
    required this.hasApiKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF1C1917)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  ls.t('ai_daily_digest'),
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!loading)
                  GestureDetector(
                    onTap: hasApiKey ? onRefresh : null,
                    child: Icon(
                      Icons.refresh_rounded,
                      color: hasApiKey ? AppColors.primaryLight : AppColors.textMuted,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: loading
                ? AiThinkingWidget(message: ls.t('analyzing_day'))
                : !hasApiKey
                    ? Text(
                        ls.t('add_api_key'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      )
                    : digest.isEmpty
                        ? GestureDetector(
                            onTap: onRefresh,
                            child: Text(
                              ls.t('tap_to_generate'),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          )
                        : Text(
                            digest,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, ls.t('nav_home')),
      (Icons.work_rounded, Icons.work_outline_rounded, ls.t('nav_work')),
      (Icons.favorite_rounded, Icons.favorite_border_rounded, 'Life'),
      (Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, ls.t('nav_finance')),
      (Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Calendar'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.textMuted.withOpacity(0.15)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.$1 : item.$2,
                          color: selected ? AppColors.primary : AppColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: selected ? AppColors.primary : AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          child: Text(item.$3),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
