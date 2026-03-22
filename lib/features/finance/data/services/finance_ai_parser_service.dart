import 'dart:convert';
import '../../../../services/claude_service.dart';
import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';
import '../../domain/models/income_stream.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/parsed_finance_input.dart';

class FinanceAiParserService {
  final ClaudeService _claude;

  FinanceAiParserService({ClaudeService? claude})
      : _claude = claude ?? ClaudeService();

  static String get _system => '''
You are a personal finance parser. Extract structured data from natural language input.

Return ONLY valid JSON, no explanation.

For DEBT entries (user owes money):
{
  "type": "debt",
  "title": "string",
  "creditor_name": "string",
  "category": "friend|family|studentLoan|bankLoan|creditCard|other",
  "amount": number,
  "currency": "USD|KGS",
  "due_date": "YYYY-MM-DD or null",
  "monthly_payment_goal": number or null,
  "priority": "low|medium|high",
  "notes": "string or null",
  "confidence": {
    "title": 0.0-1.0,
    "creditor_name": 0.0-1.0,
    "category": 0.0-1.0,
    "amount": 0.0-1.0,
    "currency": 0.0-1.0,
    "due_date": 0.0-1.0,
    "priority": 0.0-1.0
  }
}

For OBLIGATION entries (recurring payment):
{
  "type": "obligation",
  "title": "string",
  "category": "rent|utilities|subscription|insurance|salary|taxes|loan|other",
  "amount": number,
  "currency": "USD|KGS",
  "frequency": "weekly|biweekly|monthly|quarterly|annual",
  "due_day_of_month": number or null,
  "notes": "string or null",
  "confidence": {
    "title": 0.0-1.0,
    "category": 0.0-1.0,
    "amount": 0.0-1.0,
    "currency": 0.0-1.0,
    "frequency": 0.0-1.0,
    "due_day_of_month": 0.0-1.0
  }
}

For INCOME entries (recurring or one-time income):
{
  "type": "income",
  "title": "string",
  "category": "freelance|salary|project|youtube|sponsorship|investment|realEstate|other",
  "amount": number,
  "currency": "USD|KGS",
  "is_one_time": true|false,
  "frequency": "weekly|biweekly|monthly|quarterly|annual (only if is_one_time=false)",
  "date": "YYYY-MM-DD (only if is_one_time=true, default today)",
  "notes": "string or null",
  "confidence": {
    "title": 0.0-1.0,
    "category": 0.0-1.0,
    "amount": 0.0-1.0,
    "is_one_time": 0.0-1.0,
    "frequency": 0.0-1.0
  }
}

For EXPENSE entries (one-time spending):
{
  "type": "expense",
  "title": "string",
  "category": "food|transport|shopping|entertainment|health|education|travel|other",
  "amount": number,
  "currency": "USD|KGS",
  "date": "YYYY-MM-DD",
  "notes": "string or null",
  "confidence": {
    "title": 0.0-1.0,
    "category": 0.0-1.0,
    "amount": 0.0-1.0
  }
}

If unclear, return: { "type": "unknown" }

Rules:
- Treat "every month", "monthly", "/mo", "per month" as frequency: monthly
- Treat "I owe", "borrowed from", "I need to pay back" as debt
- Treat "I pay X for Y", "my X costs Y/month", "subscription" as obligation
- Treat "I earn", "I make", "my income", "revenue from", "I get paid" as income
- Treat "got paid for", "received \$X for", "booked", "sold for", "client paid" as one-time income (is_one_time=true)
- Treat "chalet", "rental", "booking", "property" as category: realEstate
- If income has no frequency words ("per month", "monthly", etc.) and sounds like a single event, set is_one_time=true
- Treat "I spent", "I bought", "cost me", "paid for" (one-time) as expense
- Default currency USD unless user says "som", "сом", "KGS"
- For expense date: default to today if not specified
- If due date is relative ("next month", "in 3 months"), compute from today: ''' +
      DateTime.now().toIso8601String().substring(0, 10) +
      '''
- Confidence 0.9+ = clear/explicit. 0.5-0.9 = inferred. Below 0.5 = guessed.
''';

  Future<ParsedFinanceInput> parse(String rawInput) async {
    final result = await _claude.callRaw(
      rawInput,
      systemPrompt: _system,
      maxTokens: 512,
    );

    try {
      final jsonStr = _extractJson(result);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _buildParsed(rawInput, data);
    } catch (_) {
      return ParsedFinanceInput.unknown(rawInput);
    }
  }

  String _extractJson(String text) {
    // Strip markdown code fences if present
    final cleaned = text.trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1) throw const FormatException('no JSON');
    return cleaned.substring(start, end + 1);
  }

  ParsedFinanceInput _buildParsed(
      String raw, Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'unknown';
    final conf = data['confidence'] as Map<String, dynamic>? ?? {};

    double c(String key, {double fallback = 0.5}) =>
        (conf[key] as num?)?.toDouble() ?? fallback;

    bool needsConf(String key, {double threshold = 0.75}) =>
        c(key) < threshold;

    if (type == 'debt') {
      final parsed = ParsedDebt(
        title: ParsedField(
          value: data['title'] as String? ?? 'Unnamed debt',
          confidence: c('title'),
          needsConfirmation: needsConf('title'),
        ),
        creditorName: ParsedField(
          value: data['creditor_name'] as String? ?? '',
          confidence: c('creditor_name'),
          needsConfirmation: needsConf('creditor_name'),
        ),
        category: ParsedField(
          value: _parseDebtCategory(data['category']),
          confidence: c('category'),
          needsConfirmation: needsConf('category'),
        ),
        amount: ParsedField(
          value: (data['amount'] as num?)?.toDouble() ?? 0.0,
          confidence: c('amount'),
          needsConfirmation: needsConf('amount') || (data['amount'] == null),
        ),
        currency: ParsedField(
          value: data['currency'] as String? ?? 'USD',
          confidence: c('currency'),
          needsConfirmation: needsConf('currency'),
        ),
        dueDate: ParsedField(
          value: _parseDate(data['due_date']),
          confidence: c('due_date'),
          needsConfirmation: data['due_date'] == null,
        ),
        monthlyPaymentGoal: ParsedField(
          value: (data['monthly_payment_goal'] as num?)?.toDouble(),
          confidence: 0.9,
        ),
        priority: ParsedField(
          value: _parseDebtPriority(data['priority']),
          confidence: c('priority'),
          needsConfirmation: needsConf('priority'),
        ),
        notes: data['notes'] as String?,
      );

      return ParsedFinanceInput(
        type: ParsedFinanceType.debt,
        debt: parsed,
        rawInput: raw,
        overallConfidence: _avgConfidence(conf),
        clarificationMessage: parsed.hasAmbiguity
            ? 'Please confirm: ${parsed.ambiguousFields.join(', ')}'
            : null,
      );
    }

    if (type == 'obligation') {
      final parsed = ParsedObligation(
        title: ParsedField(
          value: data['title'] as String? ?? 'Unnamed obligation',
          confidence: c('title'),
          needsConfirmation: needsConf('title'),
        ),
        category: ParsedField(
          value: _parseObligationCategory(data['category']),
          confidence: c('category'),
          needsConfirmation: needsConf('category'),
        ),
        amount: ParsedField(
          value: (data['amount'] as num?)?.toDouble() ?? 0.0,
          confidence: c('amount'),
          needsConfirmation: needsConf('amount') || (data['amount'] == null),
        ),
        currency: ParsedField(
          value: data['currency'] as String? ?? 'USD',
          confidence: c('currency'),
          needsConfirmation: needsConf('currency'),
        ),
        frequency: ParsedField(
          value: _parseFrequency(data['frequency']),
          confidence: c('frequency'),
          needsConfirmation: needsConf('frequency'),
        ),
        dueDayOfMonth: ParsedField(
          value: data['due_day_of_month'] as int?,
          confidence: c('due_day_of_month'),
          needsConfirmation: data['due_day_of_month'] == null,
        ),
        notes: data['notes'] as String?,
      );

      return ParsedFinanceInput(
        type: ParsedFinanceType.obligation,
        obligation: parsed,
        rawInput: raw,
        overallConfidence: _avgConfidence(conf),
        clarificationMessage: parsed.hasAmbiguity
            ? 'Please confirm: ${parsed.ambiguousFields.join(', ')}'
            : null,
      );
    }

    if (type == 'income') {
      final oneTime = data['is_one_time'] == true;
      final parsed = ParsedIncome(
        title: ParsedField(
          value: data['title'] as String? ?? 'Unnamed income',
          confidence: c('title'),
          needsConfirmation: needsConf('title'),
        ),
        category: ParsedField(
          value: _parseIncomeCategory(data['category']),
          confidence: c('category'),
          needsConfirmation: needsConf('category'),
        ),
        amount: ParsedField(
          value: (data['amount'] as num?)?.toDouble() ?? 0.0,
          confidence: c('amount'),
          needsConfirmation: needsConf('amount') || (data['amount'] == null),
        ),
        currency: ParsedField(
          value: data['currency'] as String? ?? 'USD',
          confidence: c('currency', fallback: 0.8),
        ),
        frequency: ParsedField(
          value: _parseFrequency(data['frequency']),
          confidence: c('frequency'),
          needsConfirmation: !oneTime && needsConf('frequency'),
        ),
        isOneTime: ParsedField(
          value: oneTime,
          confidence: c('is_one_time', fallback: 0.8),
        ),
        date: ParsedField(
          value: oneTime ? (_parseDate(data['date']) ?? DateTime.now()) : null,
          confidence: 0.8,
        ),
        notes: data['notes'] as String?,
      );

      return ParsedFinanceInput(
        type: ParsedFinanceType.income,
        income: parsed,
        rawInput: raw,
        overallConfidence: _avgConfidence(conf),
        clarificationMessage: parsed.hasAmbiguity
            ? 'Please confirm: ${parsed.ambiguousFields.join(', ')}'
            : null,
      );
    }

    if (type == 'expense') {
      final parsed = ParsedExpense(
        title: ParsedField(
          value: data['title'] as String? ?? 'Unnamed expense',
          confidence: c('title'),
          needsConfirmation: needsConf('title'),
        ),
        amount: ParsedField(
          value: (data['amount'] as num?)?.toDouble() ?? 0.0,
          confidence: c('amount'),
          needsConfirmation: needsConf('amount') || (data['amount'] == null),
        ),
        currency: ParsedField(
          value: data['currency'] as String? ?? 'USD',
          confidence: c('currency', fallback: 0.8),
        ),
        category: ParsedField(
          value: _parseExpenseCategory(data['category']),
          confidence: c('category'),
          needsConfirmation: needsConf('category'),
        ),
        date: ParsedField(
          value: _parseDate(data['date']) ?? DateTime.now(),
          confidence: c('date', fallback: 0.8),
        ),
        notes: data['notes'] as String?,
      );

      return ParsedFinanceInput(
        type: ParsedFinanceType.expense,
        expense: parsed,
        rawInput: raw,
        overallConfidence: _avgConfidence(conf),
        clarificationMessage: parsed.hasAmbiguity
            ? 'Please confirm: ${parsed.ambiguousFields.join(', ')}'
            : null,
      );
    }

    return ParsedFinanceInput.unknown(raw);
  }

  double _avgConfidence(Map<String, dynamic> conf) {
    if (conf.isEmpty) return 0.5;
    final values = conf.values.map((v) => (v as num).toDouble()).toList();
    return values.reduce((a, b) => a + b) / values.length;
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    return DateTime.tryParse(val.toString());
  }

  DebtCategory _parseDebtCategory(dynamic val) {
    return DebtCategory.values.firstWhere(
      (e) => e.name == val?.toString(),
      orElse: () => DebtCategory.other,
    );
  }

  DebtPriority _parseDebtPriority(dynamic val) {
    return DebtPriority.values.firstWhere(
      (e) => e.name == val?.toString(),
      orElse: () => DebtPriority.medium,
    );
  }

  ObligationCategory _parseObligationCategory(dynamic val) {
    return ObligationCategory.values.firstWhere(
      (e) => e.name == val?.toString(),
      orElse: () => ObligationCategory.other,
    );
  }

  ObligationFrequency _parseFrequency(dynamic val) {
    return ObligationFrequency.values.firstWhere(
      (e) => e.name == val?.toString(),
      orElse: () => ObligationFrequency.monthly,
    );
  }

  IncomeCategory _parseIncomeCategory(dynamic val) {
    return IncomeCategory.values.firstWhere(
      (e) => e.name == val?.toString(),
      orElse: () => IncomeCategory.other,
    );
  }

  ExpenseCategory _parseExpenseCategory(dynamic val) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == val?.toString(),
      orElse: () => ExpenseCategory.other,
    );
  }
}
