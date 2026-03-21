import 'package:flutter/foundation.dart';
import '../../../gamification/data/services/gamification_event_bus.dart';
import '../../../gamification/domain/models/gamification_event.dart';
import '../../data/repositories/local_finance_repository.dart';
import '../../data/services/finance_ai_parser_service.dart';
import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';
import '../../domain/models/income_stream.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/parsed_finance_input.dart';

class FinanceViewModel extends ChangeNotifier {
  FinanceViewModel({
    LocalFinanceRepository? repo,
    FinanceAiParserService? parser,
  })  : _repo = repo ?? LocalFinanceRepository(),
        _parser = parser ?? FinanceAiParserService() {
    _init();
  }

  final LocalFinanceRepository _repo;
  final FinanceAiParserService _parser;

  List<DebtItem> _debts = [];
  List<ObligationItem> _obligations = [];
  List<IncomeStream> _incomeStreams = [];
  List<Expense> _expenses = [];
  bool _isParsingInput = false;
  ParsedFinanceInput? _pendingInput;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<DebtItem> get debts => List.unmodifiable(_debts);
  List<ObligationItem> get obligations => List.unmodifiable(_obligations);
  bool get isParsingInput => _isParsingInput;
  ParsedFinanceInput? get pendingInput => _pendingInput;

  List<DebtItem> get activeDebts =>
      _debts.where((d) => d.status != DebtStatus.paid).toList();

  List<DebtItem> get overdueDebts =>
      _debts.where((d) => d.isOverdue).toList();

  List<DebtItem> get dueThisWeekDebts =>
      _debts.where((d) => d.isDueThisWeek).toList();

  List<ObligationItem> get activeObligations =>
      _obligations.where((o) => o.isActive).toList();

  List<ObligationItem> get subscriptions =>
      activeObligations.where((o) => o.isSubscription).toList();

  List<ObligationItem> get obligationsDueThisWeek =>
      activeObligations.where((o) => o.isDueThisWeek).toList();

  // ── Income & Expense Getters ────────────────────────────────────────────────

  List<IncomeStream> get incomeStreams => List.unmodifiable(_incomeStreams);
  List<IncomeStream> get activeIncomeStreams =>
      _incomeStreams.where((i) => i.isActive).toList();
  List<Expense> get expenses => List.unmodifiable(_expenses);

  List<Expense> get thisMonthExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .toList();
  }

  // ── Totals ─────────────────────────────────────────────────────────────────

  double get totalDebt =>
      activeDebts.fold(0, (sum, d) => sum + d.remainingAmount);

  double get totalMonthlyObligations =>
      activeObligations.fold(0, (sum, o) => sum + o.monthlyCost);

  double get totalMonthlySubscriptions =>
      subscriptions.fold(0, (sum, o) => sum + o.monthlyCost);

  double get totalMonthlyIncome =>
      activeIncomeStreams.fold(0.0, (sum, i) => sum + i.monthlyIncome);

  double get totalMonthlyExpenses =>
      thisMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

  double get monthlyCashFlow =>
      totalMonthlyIncome - totalMonthlyObligations - totalMonthlyExpenses;

  /// Recommended next payment: highest priority active debt with due date
  DebtItem? get recommendedNextPayment {
    final candidates = activeDebts
        .where((d) => d.monthlyPaymentGoal != null || d.dueDate != null)
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      // Sort: overdue first, then by priority desc, then by remaining amount
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      final pc = b.priority.index.compareTo(a.priority.index);
      if (pc != 0) return pc;
      return b.remainingAmount.compareTo(a.remainingAmount);
    });
    return candidates.first;
  }

  /// Debts grouped by category
  Map<DebtCategory, List<DebtItem>> get debtsByCategory {
    final map = <DebtCategory, List<DebtItem>>{};
    for (final debt in activeDebts) {
      map.putIfAbsent(debt.category, () => []).add(debt);
    }
    return map;
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await _repo.init();
    _debts = _repo.getDebts();
    _obligations = _repo.getObligations();
    _incomeStreams = _repo.getIncomeStreams();
    _expenses = _repo.getExpenses();
    notifyListeners();
  }

  // ── AI Input Parsing ───────────────────────────────────────────────────────

  Future<void> parseInput(String rawText) async {
    if (rawText.trim().isEmpty) return;
    _isParsingInput = true;
    notifyListeners();

    final result = await _parser.parse(rawText);
    _pendingInput = result;
    _isParsingInput = false;
    notifyListeners();
  }

  void clearPendingInput() {
    _pendingInput = null;
    notifyListeners();
  }

  // ── Confirm & Save Parsed Input ────────────────────────────────────────────

  Future<void> confirmParsedDebt(DebtItem debt) async {
    await _repo.saveDebt(debt);
    _debts = _repo.getDebts();
    _pendingInput = null;
    notifyListeners();
  }

  Future<void> confirmParsedObligation(ObligationItem obligation) async {
    await _repo.saveObligation(obligation);
    _obligations = _repo.getObligations();
    _pendingInput = null;
    notifyListeners();
  }

  // ── Debt CRUD ──────────────────────────────────────────────────────────────

  Future<void> addDebt(DebtItem debt) async {
    await _repo.saveDebt(debt);
    _debts = _repo.getDebts();
    notifyListeners();
  }

  Future<void> updateDebt(DebtItem debt) async {
    debt.updatedAt = DateTime.now();
    await _repo.updateDebt(debt);
    _debts = _repo.getDebts();
    notifyListeners();
  }

  Future<void> deleteDebt(String id) async {
    await _repo.deleteDebt(id);
    _debts = _repo.getDebts();
    notifyListeners();
  }

  Future<void> markDebtPaid(String id) async {
    final debt = _debts.firstWhere((d) => d.id == id);
    debt.remainingAmount = 0;
    debt.status = DebtStatus.paid;
    await updateDebt(debt);
  }

  Future<void> recordDebtPayment(String id, double amount) async {
    final debt = _debts.firstWhere((d) => d.id == id);
    debt.remainingAmount = (debt.remainingAmount - amount).clamp(0, double.infinity);
    if (debt.remainingAmount == 0) debt.status = DebtStatus.paid;
    await updateDebt(debt);
    GamificationEventBus.emit(GamificationEventType.debtPaymentLogged,
        description: debt.title);
  }

  // ── Obligation CRUD ────────────────────────────────────────────────────────

  Future<void> addObligation(ObligationItem obligation) async {
    await _repo.saveObligation(obligation);
    _obligations = _repo.getObligations();
    GamificationEventBus.emit(GamificationEventType.obligationTracked,
        description: obligation.title);
    notifyListeners();
  }

  Future<void> deleteObligation(String id) async {
    await _repo.deleteObligation(id);
    _obligations = _repo.getObligations();
    notifyListeners();
  }

  // ── Income Stream CRUD ──────────────────────────────────────────────────────

  Future<void> addIncomeStream(IncomeStream income) async {
    await _repo.saveIncomeStream(income);
    _incomeStreams = _repo.getIncomeStreams();
    notifyListeners();
  }

  Future<void> updateIncomeStream(IncomeStream income) async {
    income.updatedAt = DateTime.now();
    await _repo.updateIncomeStream(income);
    _incomeStreams = _repo.getIncomeStreams();
    notifyListeners();
  }

  Future<void> deleteIncomeStream(String id) async {
    await _repo.deleteIncomeStream(id);
    _incomeStreams = _repo.getIncomeStreams();
    notifyListeners();
  }

  // ── Expense CRUD ────────────────────────────────────────────────────────────

  Future<void> addExpense(Expense expense) async {
    await _repo.saveExpense(expense);
    _expenses = _repo.getExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    _expenses = _repo.getExpenses();
    notifyListeners();
  }

  // ── Confirm Parsed Income / Expense ─────────────────────────────────────────

  Future<void> confirmParsedIncome(IncomeStream income) async {
    await _repo.saveIncomeStream(income);
    _incomeStreams = _repo.getIncomeStreams();
    _pendingInput = null;
    notifyListeners();
  }

  Future<void> confirmParsedExpense(Expense expense) async {
    await _repo.saveExpense(expense);
    _expenses = _repo.getExpenses();
    _pendingInput = null;
    notifyListeners();
  }
}
