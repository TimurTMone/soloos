import 'package:uuid/uuid.dart';
import '../models/app_models.dart';
import '../features/finance/domain/models/debt_item.dart';
import '../features/finance/domain/models/obligation_item.dart';
import '../features/finance/domain/models/income_stream.dart';
import '../features/finance/domain/models/expense.dart';
import '../features/finance/data/repositories/local_finance_repository.dart';
import 'storage_service.dart';

const _uuid = Uuid();

/// Seeds realistic demo data so the app looks alive on first open.
/// Only runs once — checks for existing data first.
class DemoDataSeeder {
  static Future<void> seedIfEmpty(StorageService storage) async {
    // Don't seed if user already has data
    if (storage.getProjects().isNotEmpty ||
        storage.getHabits().isNotEmpty ||
        storage.getIdeas().isNotEmpty) {
      return;
    }

    await _seedUser(storage);
    await _seedProjects(storage);
    await _seedHabits(storage);
    await _seedIdeas(storage);
    await _seedContacts(storage);
    await _seedStandupLogs(storage);
    await _seedFinance();
  }

  static Future<void> _seedUser(StorageService s) async {
    await s.setUserName('Timur Mone');
    await s.setOnboardingDone();
    await s.setLastAiDigest(
      'Good morning, Timur. Revenue is strong at \$99K/mo across 3 streams. '
      'Solo OS v1.0 is nearly ship-ready — 2 tasks left on the Flutter app. '
      'YouTube upload is overdue by 2 days — your audience expects consistency. '
      'Chalet Karakol booking season starts next month, review pricing. '
      'Today\'s focus: finalize subscription flow in Solo OS and record YouTube episode.',
    );
    await s.setLastDigestDate(DateTime.now().toIso8601String());
  }

  static Future<void> _seedProjects(StorageService s) async {
    final now = DateTime.now();
    await s.saveProjects([
      Project(
        id: _uuid.v4(),
        name: 'Solo OS — Flutter App',
        description: 'AI-powered operating system for solopreneurs',
        tasks: [
          Task(
            id: _uuid.v4(),
            title: 'Implement subscription with RevenueCat',
            isDone: true,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 6)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Claude API proxy on Vercel',
            isDone: true,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Custom app icon & branding',
            isDone: true,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 4)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'TestFlight & APK distribution',
            isDone: false,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Friends & family beta launch',
            isDone: false,
            priority: 'high',
            createdAt: now,
          ),
          Task(
            id: _uuid.v4(),
            title: 'App Store & Google Play submission',
            isDone: false,
            priority: 'medium',
            createdAt: now,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Project(
        id: _uuid.v4(),
        name: 'YouTube Channel',
        description: 'Tech, building in public, solopreneur journey',
        tasks: [
          Task(
            id: _uuid.v4(),
            title: 'Script: "I built an app in 24 hours with AI"',
            isDone: true,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Record & edit episode',
            isDone: false,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Design thumbnail',
            isDone: false,
            priority: 'medium',
            createdAt: now,
          ),
          Task(
            id: _uuid.v4(),
            title: 'Schedule upload & write description',
            isDone: false,
            priority: 'medium',
            createdAt: now,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Project(
        id: _uuid.v4(),
        name: 'Chalet Karakol',
        description: 'Mountain chalet property management & bookings',
        tasks: [
          Task(
            id: _uuid.v4(),
            title: 'Review summer season pricing',
            isDone: false,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Update Booking.com listing photos',
            isDone: true,
            priority: 'medium',
            createdAt: now.subtract(const Duration(days: 7)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Schedule spring maintenance',
            isDone: false,
            priority: 'medium',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      Project(
        id: _uuid.v4(),
        name: 'SaaS Products',
        description: 'Portfolio of SaaS tools — operations & growth',
        tasks: [
          Task(
            id: _uuid.v4(),
            title: 'Review monthly MRR dashboard',
            isDone: true,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Churn analysis — Q1 cohort',
            isDone: false,
            priority: 'high',
            createdAt: now,
          ),
          Task(
            id: _uuid.v4(),
            title: 'Plan Q2 feature roadmap',
            isDone: false,
            priority: 'medium',
            createdAt: now,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 120)),
      ),
    ]);
  }

  static Future<void> _seedHabits(StorageService s) async {
    final now = DateTime.now();
    List<DateTime> streak(int days) =>
        List.generate(days, (i) => DateTime(now.year, now.month, now.day - i));

    await s.saveHabits([
      Habit(
        id: _uuid.v4(),
        name: 'Morning workout',
        emoji: '💪',
        frequency: 'daily',
        completedDates: streak(14),
      ),
      Habit(
        id: _uuid.v4(),
        name: 'Build in public (ship something)',
        emoji: '🚀',
        frequency: 'daily',
        completedDates: streak(9),
      ),
      Habit(
        id: _uuid.v4(),
        name: 'Read 30 min',
        emoji: '📚',
        frequency: 'daily',
        completedDates: streak(7)..removeAt(0), // not done today
      ),
      Habit(
        id: _uuid.v4(),
        name: 'Family dinner — no screens',
        emoji: '👨‍👩‍👧‍👦',
        frequency: 'daily',
        completedDates: streak(21),
      ),
      Habit(
        id: _uuid.v4(),
        name: 'Review financials',
        emoji: '💰',
        frequency: 'weekdays',
        completedDates: streak(5),
      ),
    ]);
  }

  static Future<void> _seedIdeas(StorageService s) async {
    final now = DateTime.now();
    await s.saveIdeas([
      Idea(
        id: _uuid.v4(),
        title: 'Solo OS marketplace — sell templates & workflows',
        description:
            'Let power users create and sell Solo OS workflow templates, '
            'habit packs, and finance dashboards. Take 20% platform fee.',
        status: IdeaStatus.active,
        notes: [
          'Gumroad for Solo OS — creators earn, we grow the ecosystem',
          'Start with curated templates, open up later',
        ],
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Idea(
        id: _uuid.v4(),
        title: 'AI property manager for Chalet Karakol',
        description:
            'Automated guest messaging, dynamic pricing based on season/demand, '
            'and maintenance scheduling — all AI-driven.',
        status: IdeaStatus.active,
        notes: [
          'Could be a standalone SaaS for Airbnb/Booking hosts',
        ],
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Idea(
        id: _uuid.v4(),
        title: 'YouTube → SaaS funnel course',
        description:
            'Course teaching creators how to turn YouTube audiences into '
            'SaaS customers. Based on my own playbook.',
        status: IdeaStatus.active,
        notes: [],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);
  }

  static Future<void> _seedContacts(StorageService s) async {
    final now = DateTime.now();
    await s.saveContacts([
      Contact(
        id: _uuid.v4(),
        name: 'Mom',
        emoji: '❤️',
        birthday: DateTime(now.year, now.month + 1, 15),
        relationship: 'family',
        notes: 'Call every Sunday',
      ),
      Contact(
        id: _uuid.v4(),
        name: 'Dad',
        emoji: '💙',
        birthday: DateTime(now.year, 9, 3),
        relationship: 'family',
        notes: 'Helps manage Chalet Karakol on-site',
      ),
      Contact(
        id: _uuid.v4(),
        name: 'Wife',
        emoji: '💕',
        birthday: DateTime(now.year, 6, 18),
        relationship: 'family',
        notes: 'Anniversary in June',
      ),
    ]);
  }

  static Future<void> _seedStandupLogs(StorageService s) async {
    final now = DateTime.now();
    await s.saveStandupLogs([
      StandupLog(
        id: _uuid.v4(),
        date: now.subtract(const Duration(days: 1)),
        wins: 'Shipped Claude API proxy for Solo OS. App icon looks great. '
            'YouTube video on SaaS metrics hit 50K views.',
        challenges: 'iPhone Developer Mode issue blocked physical device testing. '
            'Need to finalize subscription pricing before F&F launch.',
        priorities: 'Launch Solo OS beta to friends & family. '
            'Record next YouTube episode. Review Chalet Karakol bookings.',
        aiResponse:
            'Strong shipping velocity on Solo OS, Timur. The proxy was the right call — '
            'removing API key friction will 10x your conversion from trial to active user. '
            'For pricing: start at \$9.99/mo, \$79.99/yr — you can always adjust. '
            'Don\'t let perfect be the enemy of shipped. Your \$99K/mo revenue gives you '
            'runway to iterate. Ship the beta today, gather feedback this week.',
      ),
    ]);
  }

  static Future<void> _seedFinance() async {
    final repo = LocalFinanceRepository();
    await repo.init();

    // ── Income streams ─────────────────────────────────────────
    await repo.saveIncomeStream(IncomeStream(
      title: 'Chalet Karakol',
      category: IncomeCategory.realEstate,
      amount: 1000,
      frequency: ObligationFrequency.monthly,
      notes: 'Mountain chalet rental income',
    ));
    await repo.saveIncomeStream(IncomeStream(
      title: 'YouTube',
      category: IncomeCategory.youtube,
      amount: 15000,
      frequency: ObligationFrequency.monthly,
      notes: 'AdSense + sponsorships',
    ));
    await repo.saveIncomeStream(IncomeStream(
      title: 'SaaS Products',
      category: IncomeCategory.other,
      amount: 83000,
      frequency: ObligationFrequency.monthly,
      notes: 'MRR across SaaS portfolio',
    ));

    // ── Obligations (no rent — homeowner) ──────────────────────
    await repo.saveObligation(ObligationItem(
      title: 'Kindergarten',
      category: ObligationCategory.other,
      amount: 800,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 1,
    ));
    await repo.saveObligation(ObligationItem(
      title: 'Private School',
      category: ObligationCategory.other,
      amount: 1500,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 5,
    ));
    await repo.saveObligation(ObligationItem(
      title: 'Utilities (electric, water, internet)',
      category: ObligationCategory.utilities,
      amount: 200,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 15,
    ));
    await repo.saveObligation(ObligationItem(
      title: 'Health Insurance (family)',
      category: ObligationCategory.insurance,
      amount: 650,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 10,
    ));
    await repo.saveObligation(ObligationItem(
      title: 'Car Insurance',
      category: ObligationCategory.insurance,
      amount: 120,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 20,
    ));
    await repo.saveObligation(ObligationItem(
      title: 'Claude API (Anthropic)',
      category: ObligationCategory.subscription,
      amount: 200,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 1,
    ));
    await repo.saveObligation(ObligationItem(
      title: 'Vercel Pro',
      category: ObligationCategory.subscription,
      amount: 20,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 12,
    ));
    await repo.saveObligation(ObligationItem(
      title: 'Apple Developer Program',
      category: ObligationCategory.subscription,
      amount: 99,
      frequency: ObligationFrequency.annual,
      dueDayOfMonth: 1,
    ));

    // ── No debts — clean balance sheet ─────────────────────────

    // ── Recent expenses ────────────────────────────────────────
    final now = DateTime.now();
    for (final e in [
      Expense(title: 'Groceries (Frunze)', amount: 85, category: ExpenseCategory.food, date: now),
      Expense(title: 'Gas — fill up', amount: 55, category: ExpenseCategory.transport, date: now),
      Expense(title: 'Kids birthday gift', amount: 45, category: ExpenseCategory.shopping, date: now.subtract(const Duration(days: 1))),
      Expense(title: 'Groceries', amount: 120, category: ExpenseCategory.food, date: now.subtract(const Duration(days: 2))),
      Expense(title: 'Family dinner out', amount: 65, category: ExpenseCategory.food, date: now.subtract(const Duration(days: 3))),
      Expense(title: 'Gas', amount: 50, category: ExpenseCategory.transport, date: now.subtract(const Duration(days: 4))),
      Expense(title: 'New monitor (work)', amount: 380, category: ExpenseCategory.shopping, date: now.subtract(const Duration(days: 5))),
      Expense(title: 'Pharmacy', amount: 25, category: ExpenseCategory.health, date: now.subtract(const Duration(days: 5))),
      Expense(title: 'Kids swimming class', amount: 40, category: ExpenseCategory.education, date: now.subtract(const Duration(days: 6))),
      Expense(title: 'Coffee & snacks', amount: 12, category: ExpenseCategory.food, date: now.subtract(const Duration(days: 6))),
    ]) {
      await repo.saveExpense(e);
    }
  }
}
