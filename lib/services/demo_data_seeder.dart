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
    await s.setUserName('Alex');
    await s.setOnboardingDone();
    await s.setLastAiDigest(
      'Good morning, Alex. You have 4 open tasks across 2 projects. '
      'Your 7-day habit streak is strong — don\'t break it today. '
      'Rent is due in 3 days. Consider reviewing your SaaS idea — '
      'it\'s been sitting idle for a week. Today\'s focus: finish the '
      'landing page and do your evening journaling.',
    );
    await s.setLastDigestDate(DateTime.now().toIso8601String());
  }

  static Future<void> _seedProjects(StorageService s) async {
    final now = DateTime.now();
    await s.saveProjects([
      Project(
        id: _uuid.v4(),
        name: 'Launch Landing Page',
        description: 'Marketing site for the new product',
        tasks: [
          Task(
            id: _uuid.v4(),
            title: 'Write hero copy',
            isDone: true,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Design mockup in Figma',
            isDone: true,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 4)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Build responsive layout',
            isDone: false,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Set up analytics',
            isDone: false,
            priority: 'medium',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Connect Stripe checkout',
            isDone: false,
            priority: 'medium',
            createdAt: now,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Project(
        id: _uuid.v4(),
        name: 'YouTube Channel',
        description: 'Weekly content about solopreneur life',
        tasks: [
          Task(
            id: _uuid.v4(),
            title: 'Script episode #4',
            isDone: true,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Record episode #4',
            isDone: false,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Edit & upload',
            isDone: false,
            priority: 'medium',
            createdAt: now,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      Project(
        id: _uuid.v4(),
        name: 'Client: Bloom Studio',
        description: 'Brand identity & website redesign',
        tasks: [
          Task(
            id: _uuid.v4(),
            title: 'Mood board presentation',
            isDone: true,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 10)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Logo concepts (3 options)',
            isDone: true,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 7)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Final logo delivery',
            isDone: true,
            priority: 'medium',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Website wireframes',
            isDone: false,
            priority: 'high',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 21)),
      ),
    ]);
  }

  static Future<void> _seedHabits(StorageService s) async {
    final now = DateTime.now();
    // Generate past completion dates for streaks
    List<DateTime> streak(int days) =>
        List.generate(days, (i) => DateTime(now.year, now.month, now.day - i));

    await s.saveHabits([
      Habit(
        id: _uuid.v4(),
        name: 'Morning journaling',
        emoji: '📝',
        frequency: 'daily',
        completedDates: streak(7),
      ),
      Habit(
        id: _uuid.v4(),
        name: 'Exercise 30min',
        emoji: '💪',
        frequency: 'daily',
        completedDates: streak(12)..removeAt(0), // not done today
      ),
      Habit(
        id: _uuid.v4(),
        name: 'Read 20 pages',
        emoji: '📚',
        frequency: 'daily',
        completedDates: streak(5),
      ),
      Habit(
        id: _uuid.v4(),
        name: 'No social media before noon',
        emoji: '🚫',
        frequency: 'daily',
        completedDates: streak(3),
      ),
      Habit(
        id: _uuid.v4(),
        name: 'Deep work block (2h)',
        emoji: '🎯',
        frequency: 'weekdays',
        completedDates: streak(9)..removeAt(0), // not done today
      ),
    ]);
  }

  static Future<void> _seedIdeas(StorageService s) async {
    final now = DateTime.now();
    await s.saveIdeas([
      Idea(
        id: _uuid.v4(),
        title: 'SaaS for freelancer invoicing',
        description:
            'Simple invoicing tool with AI that auto-categorizes expenses '
            'and suggests tax deductions for solopreneurs.',
        status: IdeaStatus.active,
        notes: [
          'Competitors: FreshBooks, Wave — but none are AI-first',
          'Could start with a Stripe integration MVP',
        ],
        createdAt: now.subtract(const Duration(days: 10)),
        aiScript:
            'HOOK: "I saved \$4,200 on taxes last year with one tool..."\n\n'
            'PROBLEM: Freelancers lose thousands because they don\'t track expenses properly.\n\n'
            'SOLUTION: An AI that watches your bank feed, auto-categorizes every transaction, '
            'and tells you exactly what to deduct.\n\n'
            'CTA: "Drop a comment if you\'d use this — building it right now."',
      ),
      Idea(
        id: _uuid.v4(),
        title: 'Notion template marketplace',
        description:
            'Curated marketplace for premium Notion templates. '
            'Take 20% commission, creators keep 80%.',
        status: IdeaStatus.active,
        notes: [],
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Idea(
        id: _uuid.v4(),
        title: 'AI podcast summarizer',
        description:
            'Upload any podcast episode, get key takeaways, action items, '
            'and tweetable quotes in 30 seconds.',
        status: IdeaStatus.active,
        notes: [
          'Use Whisper for transcription + Claude for summarization',
        ],
        createdAt: now.subtract(const Duration(days: 2)),
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
        notes: 'Loves gardening, call on Sundays',
      ),
      Contact(
        id: _uuid.v4(),
        name: 'Jake (designer)',
        emoji: '🎨',
        birthday: DateTime(now.year, now.month, now.day + 5),
        relationship: 'friend',
        notes: 'Met at design conf, potential collab on Bloom project',
      ),
      Contact(
        id: _uuid.v4(),
        name: 'Sarah Chen',
        emoji: '💼',
        birthday: DateTime(now.year, 8, 22),
        relationship: 'mentor',
        notes: 'VC partner, gave great advice on pricing',
      ),
    ]);
  }

  static Future<void> _seedStandupLogs(StorageService s) async {
    final now = DateTime.now();
    await s.saveStandupLogs([
      StandupLog(
        id: _uuid.v4(),
        date: now.subtract(const Duration(days: 1)),
        wins: 'Finished logo delivery for Bloom Studio. Got 3 new YouTube subscribers.',
        challenges: 'Struggled with landing page copy — rewrote it 4 times.',
        priorities: 'Build responsive layout. Record YouTube episode #4.',
        aiResponse:
            'Solid progress on the client work! The landing page copy struggle is normal — '
            'try the "Problem → Agitate → Solve" framework tomorrow. '
            'Your YouTube consistency is paying off. Keep the momentum on Bloom '
            'before starting anything new.',
      ),
    ]);
  }

  static Future<void> _seedFinance() async {
    final repo = LocalFinanceRepository();
    await repo.init();

    // Income streams
    await repo.saveIncomeStream(IncomeStream(
      title: 'Freelance Design',
      category: IncomeCategory.freelance,
      amount: 4500,
      frequency: ObligationFrequency.monthly,
    ));
    await repo.saveIncomeStream(IncomeStream(
      title: 'YouTube AdSense',
      category: IncomeCategory.youtube,
      amount: 320,
      frequency: ObligationFrequency.monthly,
    ));
    await repo.saveIncomeStream(IncomeStream(
      title: 'Bloom Studio project',
      category: IncomeCategory.project,
      amount: 3000,
      frequency: ObligationFrequency.monthly,
      isOneTime: true,
      date: DateTime.now().subtract(const Duration(days: 5)),
    ));

    // Obligations
    await repo.saveObligation(ObligationItem(
      title: 'Rent',
      category: ObligationCategory.rent,
      amount: 1800,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 1,
    ));
    await repo.saveObligation(ObligationItem(
      title: 'Figma Pro',
      category: ObligationCategory.subscription,
      amount: 15,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 12,
    ));
    await repo.saveObligation(ObligationItem(
      title: 'Adobe Creative Cloud',
      category: ObligationCategory.subscription,
      amount: 55,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 20,
    ));
    await repo.saveObligation(ObligationItem(
      title: 'Health Insurance',
      category: ObligationCategory.insurance,
      amount: 380,
      frequency: ObligationFrequency.monthly,
      dueDayOfMonth: 5,
    ));

    // Debts
    await repo.saveDebt(DebtItem(
      title: 'Student Loan',
      creditorName: 'Federal',
      category: DebtCategory.studentLoan,
      originalAmount: 28000,
      remainingAmount: 19500,
      monthlyPaymentGoal: 450,
      dueDate: DateTime.now().add(const Duration(days: 15)),
    ));

    // Recent expenses
    final now = DateTime.now();
    for (final e in [
      Expense(title: 'Coworking day pass', amount: 25, category: ExpenseCategory.other, date: now),
      Expense(title: 'Uber to meeting', amount: 18, category: ExpenseCategory.transport, date: now.subtract(const Duration(days: 1))),
      Expense(title: 'Lunch', amount: 14, category: ExpenseCategory.food, date: now.subtract(const Duration(days: 1))),
      Expense(title: 'Domain renewal', amount: 12, category: ExpenseCategory.other, date: now.subtract(const Duration(days: 2))),
      Expense(title: 'Coffee supplies', amount: 32, category: ExpenseCategory.food, date: now.subtract(const Duration(days: 3))),
    ]) {
      await repo.saveExpense(e);
    }
  }
}
