import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';
import '../../domain/models/income_stream.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/parsed_finance_input.dart';

class ParseConfirmSheet extends StatefulWidget {
  final ParsedFinanceInput parsed;
  final void Function(DebtItem) onConfirmDebt;
  final void Function(ObligationItem) onConfirmObligation;
  final void Function(IncomeStream) onConfirmIncome;
  final void Function(Expense) onConfirmExpense;
  final VoidCallback onCancel;

  const ParseConfirmSheet({
    super.key,
    required this.parsed,
    required this.onConfirmDebt,
    required this.onConfirmObligation,
    required this.onConfirmIncome,
    required this.onConfirmExpense,
    required this.onCancel,
  });

  @override
  State<ParseConfirmSheet> createState() => _ParseConfirmSheetState();
}

class _ParseConfirmSheetState extends State<ParseConfirmSheet> {
  late String _title;
  late double _amount;
  late String _currency;

  // Debt-specific
  String? _creditorName;
  DebtCategory? _debtCategory;
  DebtPriority? _priority;
  DateTime? _dueDate;
  double? _monthlyPaymentGoal;

  // Obligation-specific
  ObligationCategory? _obligationCategory;
  ObligationFrequency? _frequency;
  int? _dueDayOfMonth;

  // Income-specific
  IncomeCategory? _incomeCategory;
  ObligationFrequency? _incomeFrequency;
  bool _incomeIsOneTime = false;
  DateTime? _incomeDate;

  // Expense-specific
  ExpenseCategory? _expenseCategory;
  DateTime? _expenseDate;

  @override
  void initState() {
    super.initState();
    final p = widget.parsed;
    if (p.isDebt) {
      final d = p.debt!;
      _title = d.title.value;
      _amount = d.amount.value;
      _currency = d.currency.value;
      _creditorName = d.creditorName.value;
      _debtCategory = d.category.value;
      _priority = d.priority.value;
      _dueDate = d.dueDate.value;
      _monthlyPaymentGoal = d.monthlyPaymentGoal.value;
    } else if (p.isObligation) {
      final o = p.obligation!;
      _title = o.title.value;
      _amount = o.amount.value;
      _currency = o.currency.value;
      _obligationCategory = o.category.value;
      _frequency = o.frequency.value;
      _dueDayOfMonth = o.dueDayOfMonth.value;
    } else if (p.isIncome) {
      final i = p.income!;
      _title = i.title.value;
      _amount = i.amount.value;
      _currency = i.currency.value;
      _incomeCategory = i.category.value;
      _incomeFrequency = i.frequency.value;
      _incomeIsOneTime = i.isOneTime.value;
      _incomeDate = i.date.value;
    } else if (p.isExpense) {
      final e = p.expense!;
      _title = e.title.value;
      _amount = e.amount.value;
      _currency = e.currency.value;
      _expenseCategory = e.category.value;
      _expenseDate = e.date.value;
    } else {
      _title = '';
      _amount = 0;
      _currency = 'USD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parsed;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            Expanded(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeBadge(type: p.type),
                    const SizedBox(height: 8),
                    if (p.clarificationMessage != null)
                      _AmbiguityBanner(message: p.clarificationMessage!),
                    const SizedBox(height: 16),
                    _buildFields(),
                    const SizedBox(height: 24),
                    _ActionButtons(
                      onConfirm: _handleConfirm,
                      onCancel: widget.onCancel,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    final p = widget.parsed;
    if (p.isDebt) return _buildDebtFields(p.debt!);
    if (p.isObligation) return _buildObligationFields(p.obligation!);
    if (p.isIncome) return _buildIncomeFields(p.income!);
    if (p.isExpense) return _buildExpenseFields(p.expense!);
    return const Center(
      child: Text(
        "Couldn't understand that. Try again with more detail.",
        style: TextStyle(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDebtFields(ParsedDebt d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldRow(
          label: 'Title', uncertain: d.title.needsConfirmation,
          child: _EditableText(value: _title, onChanged: (v) => setState(() => _title = v)),
        ),
        _FieldRow(
          label: 'Creditor', uncertain: d.creditorName.needsConfirmation,
          child: _EditableText(value: _creditorName ?? '', onChanged: (v) => setState(() => _creditorName = v)),
        ),
        _FieldRow(
          label: 'Amount', uncertain: d.amount.needsConfirmation,
          child: _EditableAmount(
            amount: _amount, currency: _currency,
            onAmountChanged: (v) => setState(() => _amount = v),
            onCurrencyChanged: (v) => setState(() => _currency = v),
          ),
        ),
        _FieldRow(
          label: 'Category', uncertain: d.category.needsConfirmation,
          child: _CategoryDropdown<DebtCategory>(
            value: _debtCategory ?? DebtCategory.other,
            values: DebtCategory.values,
            label: (c) => '${c.emoji} ${c.label}',
            onChanged: (v) => setState(() => _debtCategory = v),
          ),
        ),
        _FieldRow(
          label: 'Priority', uncertain: d.priority.needsConfirmation,
          child: _SegmentedPicker(
            options: ['Low', 'Medium', 'High'],
            selected: _priority?.index ?? 1,
            onChanged: (i) => setState(() => _priority = DebtPriority.values[i]),
          ),
        ),
        if (_dueDate != null || d.dueDate.needsConfirmation)
          _FieldRow(
            label: 'Due Date', uncertain: d.dueDate.needsConfirmation,
            child: _DatePicker(date: _dueDate, onChanged: (v) => setState(() => _dueDate = v)),
          ),
      ],
    );
  }

  Widget _buildObligationFields(ParsedObligation o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldRow(
          label: 'Title', uncertain: o.title.needsConfirmation,
          child: _EditableText(value: _title, onChanged: (v) => setState(() => _title = v)),
        ),
        _FieldRow(
          label: 'Category', uncertain: o.category.needsConfirmation,
          child: _CategoryDropdown<ObligationCategory>(
            value: _obligationCategory ?? ObligationCategory.other,
            values: ObligationCategory.values,
            label: (c) => '${c.emoji} ${c.label}',
            onChanged: (v) => setState(() => _obligationCategory = v),
          ),
        ),
        _FieldRow(
          label: 'Amount', uncertain: o.amount.needsConfirmation,
          child: _EditableAmount(
            amount: _amount, currency: _currency,
            onAmountChanged: (v) => setState(() => _amount = v),
            onCurrencyChanged: (v) => setState(() => _currency = v),
          ),
        ),
        _FieldRow(
          label: 'Frequency', uncertain: o.frequency.needsConfirmation,
          child: _CategoryDropdown<ObligationFrequency>(
            value: _frequency ?? ObligationFrequency.monthly,
            values: ObligationFrequency.values,
            label: (f) => f.label,
            onChanged: (v) => setState(() => _frequency = v),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeFields(ParsedIncome i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldRow(
          label: 'Title', uncertain: i.title.needsConfirmation,
          child: _EditableText(value: _title, onChanged: (v) => setState(() => _title = v)),
        ),
        _FieldRow(
          label: 'Type', uncertain: false,
          child: _SegmentedPicker(
            options: ['Recurring', 'One-time'],
            selected: _incomeIsOneTime ? 1 : 0,
            onChanged: (idx) => setState(() => _incomeIsOneTime = idx == 1),
          ),
        ),
        _FieldRow(
          label: 'Category', uncertain: i.category.needsConfirmation,
          child: _CategoryDropdown<IncomeCategory>(
            value: _incomeCategory ?? IncomeCategory.other,
            values: IncomeCategory.values,
            label: (c) => '${c.emoji} ${c.label}',
            onChanged: (v) => setState(() => _incomeCategory = v),
          ),
        ),
        _FieldRow(
          label: 'Amount', uncertain: i.amount.needsConfirmation,
          child: _EditableAmount(
            amount: _amount, currency: _currency,
            onAmountChanged: (v) => setState(() => _amount = v),
            onCurrencyChanged: (v) => setState(() => _currency = v),
          ),
        ),
        if (_incomeIsOneTime)
          _FieldRow(
            label: 'Date', uncertain: false,
            child: _DatePicker(
              date: _incomeDate,
              onChanged: (v) { if (v != null) setState(() => _incomeDate = v); },
              allowPast: true,
            ),
          )
        else
          _FieldRow(
            label: 'Frequency', uncertain: !_incomeIsOneTime && i.frequency.needsConfirmation,
            child: _CategoryDropdown<ObligationFrequency>(
              value: _incomeFrequency ?? ObligationFrequency.monthly,
              values: ObligationFrequency.values,
              label: (f) => f.label,
              onChanged: (v) => setState(() => _incomeFrequency = v),
            ),
          ),
      ],
    );
  }

  Widget _buildExpenseFields(ParsedExpense e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldRow(
          label: 'Title', uncertain: e.title.needsConfirmation,
          child: _EditableText(value: _title, onChanged: (v) => setState(() => _title = v)),
        ),
        _FieldRow(
          label: 'Category', uncertain: e.category.needsConfirmation,
          child: _CategoryDropdown<ExpenseCategory>(
            value: _expenseCategory ?? ExpenseCategory.other,
            values: ExpenseCategory.values,
            label: (c) => '${c.emoji} ${c.label}',
            onChanged: (v) => setState(() => _expenseCategory = v),
          ),
        ),
        _FieldRow(
          label: 'Amount', uncertain: e.amount.needsConfirmation,
          child: _EditableAmount(
            amount: _amount, currency: _currency,
            onAmountChanged: (v) => setState(() => _amount = v),
            onCurrencyChanged: (v) => setState(() => _currency = v),
          ),
        ),
        _FieldRow(
          label: 'Date', uncertain: false,
          child: _DatePicker(
            date: _expenseDate,
            onChanged: (v) { if (v != null) setState(() => _expenseDate = v); },
            allowPast: true,
          ),
        ),
      ],
    );
  }

  void _handleConfirm() {
    final p = widget.parsed;
    if (p.isDebt) {
      widget.onConfirmDebt(DebtItem(
        title: _title,
        creditorName: _creditorName ?? '',
        category: _debtCategory ?? DebtCategory.other,
        originalAmount: _amount,
        currency: _currency,
        dueDate: _dueDate,
        monthlyPaymentGoal: _monthlyPaymentGoal,
        priority: _priority ?? DebtPriority.medium,
      ));
    } else if (p.isObligation) {
      widget.onConfirmObligation(ObligationItem(
        title: _title,
        category: _obligationCategory ?? ObligationCategory.other,
        amount: _amount,
        currency: _currency,
        frequency: _frequency ?? ObligationFrequency.monthly,
        dueDayOfMonth: _dueDayOfMonth,
      ));
    } else if (p.isIncome) {
      widget.onConfirmIncome(IncomeStream(
        title: _title,
        category: _incomeCategory ?? IncomeCategory.other,
        amount: _amount,
        currency: _currency,
        frequency: _incomeFrequency ?? ObligationFrequency.monthly,
        isOneTime: _incomeIsOneTime,
        date: _incomeIsOneTime ? (_incomeDate ?? DateTime.now()) : null,
      ));
    } else if (p.isExpense) {
      widget.onConfirmExpense(Expense(
        title: _title,
        amount: _amount,
        currency: _currency,
        category: _expenseCategory ?? ExpenseCategory.other,
        date: _expenseDate ?? DateTime.now(),
      ));
    }
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Confirm & Save',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final ParsedFinanceType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      ParsedFinanceType.debt => ('💳 Debt', AppColors.accentRed),
      ParsedFinanceType.obligation => ('📋 Obligation', AppColors.accentBlue),
      ParsedFinanceType.income => ('💰 Income', AppColors.accentGreen),
      ParsedFinanceType.expense => ('💸 Expense', AppColors.accent),
      _ => ('❓ Unknown', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _AmbiguityBanner extends StatelessWidget {
  final String message;
  const _AmbiguityBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Text('⚠️ $message',
        style: const TextStyle(color: AppColors.accent, fontSize: 12),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final bool uncertain;
  final Widget child;
  const _FieldRow({required this.label, required this.uncertain, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              if (uncertain)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('• needs confirmation',
                      style: TextStyle(color: AppColors.accent, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _EditableText extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _EditableText({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: const InputDecoration(isDense: true),
      onChanged: onChanged,
    );
  }
}

class _EditableAmount extends StatelessWidget {
  final double amount;
  final String currency;
  final void Function(double) onAmountChanged;
  final void Function(String) onCurrencyChanged;

  const _EditableAmount({
    required this.amount,
    required this.currency,
    required this.onAmountChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: amount > 0 ? amount.toStringAsFixed(0) : '',
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(isDense: true, prefixText: '\$'),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) onAmountChanged(parsed);
            },
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: currency,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          underline: const SizedBox(),
          items: ['USD', 'KGS'].map((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              )).toList(),
          onChanged: (v) => v != null ? onCurrencyChanged(v) : null,
        ),
      ],
    );
  }
}

class _CategoryDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> values;
  final String Function(T) label;
  final void Function(T) onChanged;

  const _CategoryDropdown({
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: const InputDecoration(isDense: true),
      dropdownColor: AppColors.card,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      items: values.map((v) => DropdownMenuItem(
            value: v,
            child: Text(label(v)),
          )).toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

class _SegmentedPicker extends StatelessWidget {
  final List<String> options;
  final int selected;
  final void Function(int) onChanged;

  const _SegmentedPicker({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final isSelected = i == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              child: Text(
                options[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime? date;
  final void Function(DateTime?) onChanged;
  final bool allowPast;
  const _DatePicker({required this.date, required this.onChanged, this.allowPast = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: allowPast
              ? DateTime.now().subtract(const Duration(days: 365))
              : DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textMuted),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              date != null
                  ? '${date!.month}/${date!.day}/${date!.year}'
                  : 'Set date',
              style: TextStyle(
                color: date != null ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _ActionButtons({required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.textMuted),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Discard', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save to Finance'),
          ),
        ),
      ],
    );
  }
}
