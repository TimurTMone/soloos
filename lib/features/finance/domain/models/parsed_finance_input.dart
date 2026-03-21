import 'debt_item.dart';
import 'obligation_item.dart';
import 'income_stream.dart';
import 'expense.dart';

/// Type of entity the AI parsed from natural language
enum ParsedFinanceType { debt, obligation, income, expense, unknown }

/// A single field suggestion from the AI with a confidence level
class ParsedField<T> {
  final T value;
  final double confidence; // 0.0 – 1.0
  final bool needsConfirmation; // true if below threshold or ambiguous

  const ParsedField({
    required this.value,
    required this.confidence,
    this.needsConfirmation = false,
  });

  static ParsedField<T> sure<T>(T value) =>
      ParsedField(value: value, confidence: 0.95);

  static ParsedField<T> guessed<T>(T value) =>
      ParsedField(value: value, confidence: 0.5, needsConfirmation: true);

  static ParsedField<T> missing<T>(T fallback) =>
      ParsedField(value: fallback, confidence: 0.0, needsConfirmation: true);
}

/// Parsed debt fields from natural language
class ParsedDebt {
  final ParsedField<String> title;
  final ParsedField<String> creditorName;
  final ParsedField<DebtCategory> category;
  final ParsedField<double> amount;
  final ParsedField<String> currency;
  final ParsedField<DateTime?> dueDate;
  final ParsedField<double?> monthlyPaymentGoal;
  final ParsedField<DebtPriority> priority;
  final String? notes;

  const ParsedDebt({
    required this.title,
    required this.creditorName,
    required this.category,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.monthlyPaymentGoal,
    required this.priority,
    this.notes,
  });

  /// Fields that need confirmation before saving
  List<String> get ambiguousFields {
    final fields = <String>[];
    if (title.needsConfirmation) fields.add('title');
    if (creditorName.needsConfirmation) fields.add('creditor');
    if (category.needsConfirmation) fields.add('category');
    if (amount.needsConfirmation) fields.add('amount');
    if (currency.needsConfirmation) fields.add('currency');
    if (dueDate.needsConfirmation) fields.add('due date');
    if (priority.needsConfirmation) fields.add('priority');
    return fields;
  }

  bool get hasAmbiguity => ambiguousFields.isNotEmpty;

  DebtItem toDebtItem() => DebtItem(
        title: title.value,
        creditorName: creditorName.value,
        category: category.value,
        originalAmount: amount.value,
        currency: currency.value,
        dueDate: dueDate.value,
        monthlyPaymentGoal: monthlyPaymentGoal.value,
        priority: priority.value,
        notes: notes,
      );
}

/// Parsed obligation fields from natural language
class ParsedObligation {
  final ParsedField<String> title;
  final ParsedField<ObligationCategory> category;
  final ParsedField<double> amount;
  final ParsedField<String> currency;
  final ParsedField<ObligationFrequency> frequency;
  final ParsedField<int?> dueDayOfMonth;
  final String? notes;

  const ParsedObligation({
    required this.title,
    required this.category,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.dueDayOfMonth,
    this.notes,
  });

  List<String> get ambiguousFields {
    final fields = <String>[];
    if (title.needsConfirmation) fields.add('title');
    if (category.needsConfirmation) fields.add('category');
    if (amount.needsConfirmation) fields.add('amount');
    if (currency.needsConfirmation) fields.add('currency');
    if (frequency.needsConfirmation) fields.add('frequency');
    if (dueDayOfMonth.needsConfirmation) fields.add('due day');
    return fields;
  }

  bool get hasAmbiguity => ambiguousFields.isNotEmpty;

  ObligationItem toObligationItem() => ObligationItem(
        title: title.value,
        category: category.value,
        amount: amount.value,
        currency: currency.value,
        frequency: frequency.value,
        dueDayOfMonth: dueDayOfMonth.value,
        notes: notes,
      );
}

/// Parsed income stream from natural language
class ParsedIncome {
  final ParsedField<String> title;
  final ParsedField<IncomeCategory> category;
  final ParsedField<double> amount;
  final ParsedField<String> currency;
  final ParsedField<ObligationFrequency> frequency;
  final String? notes;

  const ParsedIncome({
    required this.title,
    required this.category,
    required this.amount,
    required this.currency,
    required this.frequency,
    this.notes,
  });

  List<String> get ambiguousFields {
    final fields = <String>[];
    if (title.needsConfirmation) fields.add('title');
    if (category.needsConfirmation) fields.add('category');
    if (amount.needsConfirmation) fields.add('amount');
    if (frequency.needsConfirmation) fields.add('frequency');
    return fields;
  }

  bool get hasAmbiguity => ambiguousFields.isNotEmpty;

  IncomeStream toIncomeStream() => IncomeStream(
        title: title.value,
        category: category.value,
        amount: amount.value,
        currency: currency.value,
        frequency: frequency.value,
        notes: notes,
      );
}

/// Parsed one-time expense from natural language
class ParsedExpense {
  final ParsedField<String> title;
  final ParsedField<double> amount;
  final ParsedField<String> currency;
  final ParsedField<ExpenseCategory> category;
  final ParsedField<DateTime> date;
  final String? notes;

  const ParsedExpense({
    required this.title,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.notes,
  });

  List<String> get ambiguousFields {
    final fields = <String>[];
    if (title.needsConfirmation) fields.add('title');
    if (amount.needsConfirmation) fields.add('amount');
    if (category.needsConfirmation) fields.add('category');
    return fields;
  }

  bool get hasAmbiguity => ambiguousFields.isNotEmpty;

  Expense toExpense() => Expense(
        title: title.value,
        amount: amount.value,
        currency: currency.value,
        category: category.value,
        date: date.value,
        notes: notes,
      );
}

/// Container for the full AI parse result
class ParsedFinanceInput {
  final ParsedFinanceType type;
  final ParsedDebt? debt;
  final ParsedObligation? obligation;
  final ParsedIncome? income;
  final ParsedExpense? expense;
  final String rawInput;
  final String? clarificationMessage;
  final double overallConfidence;

  const ParsedFinanceInput({
    required this.type,
    this.debt,
    this.obligation,
    this.income,
    this.expense,
    required this.rawInput,
    this.clarificationMessage,
    required this.overallConfidence,
  });

  bool get hasAmbiguity =>
      (debt?.hasAmbiguity ?? false) ||
      (obligation?.hasAmbiguity ?? false) ||
      (income?.hasAmbiguity ?? false) ||
      (expense?.hasAmbiguity ?? false);

  bool get isDebt => type == ParsedFinanceType.debt && debt != null;
  bool get isObligation =>
      type == ParsedFinanceType.obligation && obligation != null;
  bool get isIncome => type == ParsedFinanceType.income && income != null;
  bool get isExpense => type == ParsedFinanceType.expense && expense != null;

  static ParsedFinanceInput unknown(String raw) => ParsedFinanceInput(
        type: ParsedFinanceType.unknown,
        rawInput: raw,
        overallConfidence: 0.0,
        clarificationMessage:
            'Could not understand. Try: "I earn \$3000/month freelancing" or "Spent \$12 on lunch"',
      );
}
