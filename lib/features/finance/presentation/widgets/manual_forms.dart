import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';
import '../../domain/models/income_stream.dart';
import '../../domain/models/expense.dart';

// ── Manual add type picker ───────────────────────────────────────────────────

class ManualTypePickerSheet extends StatelessWidget {
  final VoidCallback onDebt;
  final VoidCallback onObligation;
  final VoidCallback onIncome;
  final VoidCallback onExpense;
  const ManualTypePickerSheet({
    super.key,
    required this.onDebt,
    required this.onObligation,
    required this.onIncome,
    required this.onExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Add to Finance',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  icon: '💰',
                  label: 'Income',
                  subtitle: 'Recurring earnings',
                  color: AppColors.accentGreen,
                  onTap: onIncome,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  icon: '💸',
                  label: 'Expense',
                  subtitle: 'One-time spending',
                  color: AppColors.accent,
                  onTap: onExpense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  icon: '💳',
                  label: 'Debt',
                  subtitle: 'I owe someone',
                  color: AppColors.accentRed,
                  onTap: onDebt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  icon: '📋',
                  label: 'Obligation',
                  subtitle: 'Recurring bill',
                  color: AppColors.accentBlue,
                  onTap: onObligation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _TypeButton(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Manual debt form ─────────────────────────────────────────────────────────

class ManualDebtForm extends StatefulWidget {
  final void Function(DebtItem) onSave;
  const ManualDebtForm({super.key, required this.onSave});

  @override
  State<ManualDebtForm> createState() => _ManualDebtFormState();
}

class _ManualDebtFormState extends State<ManualDebtForm> {
  final _titleCtrl = TextEditingController();
  final _creditorCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DebtCategory _category = DebtCategory.other;
  DebtPriority _priority = DebtPriority.medium;
  String _currency = 'USD';
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _creditorCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) return;
    widget.onSave(DebtItem(
      title: title,
      creditorName: _creditorCtrl.text.trim(),
      category: _category,
      originalAmount: amount,
      currency: _currency,
      dueDate: _dueDate,
      priority: _priority,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: '💳 Add Debt',
      onSave: _save,
      saveLabel: 'Save Debt',
      children: [
        _label('Title *'),
        TextField(
          controller: _titleCtrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'e.g. Student Loan'),
        ),
        const SizedBox(height: 12),
        _label('Creditor / Who you owe'),
        TextField(
          controller: _creditorCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'e.g. Bank, John'),
        ),
        const SizedBox(height: 12),
        _AmountCurrencyRow(
          amountCtrl: _amountCtrl,
          currency: _currency,
          onCurrencyChanged: (v) => setState(() => _currency = v),
        ),
        const SizedBox(height: 12),
        _label('Category'),
        DropdownButtonFormField<DebtCategory>(
          value: _category,
          decoration: const InputDecoration(isDense: true),
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          items: DebtCategory.values
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.emoji} ${c.label}'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 12),
        _label('Priority'),
        Row(
          children: DebtPriority.values.map((p) {
            final selected = _priority == p;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _priority = p),
                child: Container(
                  margin: EdgeInsets.only(
                      right: p != DebtPriority.high ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMuted),
                  ),
                  child: Text(
                    p.name[0].toUpperCase() + p.name.substring(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 12),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _label('Due Date (optional)'),
        _DatePickerField(
          date: _dueDate,
          onChanged: (d) => setState(() => _dueDate = d),
        ),
      ],
    );
  }
}

// ── Manual obligation form ───────────────────────────────────────────────────

class ManualObligationForm extends StatefulWidget {
  final void Function(ObligationItem) onSave;
  const ManualObligationForm({super.key, required this.onSave});

  @override
  State<ManualObligationForm> createState() => _ManualObligationFormState();
}

class _ManualObligationFormState extends State<ManualObligationForm> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  ObligationCategory _category = ObligationCategory.other;
  ObligationFrequency _frequency = ObligationFrequency.monthly;
  String _currency = 'USD';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) return;
    widget.onSave(ObligationItem(
      title: title,
      category: _category,
      amount: amount,
      currency: _currency,
      frequency: _frequency,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: '📋 Add Obligation',
      onSave: _save,
      saveLabel: 'Save Obligation',
      children: [
        _label('Title *'),
        TextField(
          controller: _titleCtrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'e.g. Spotify, Rent'),
        ),
        const SizedBox(height: 12),
        _AmountCurrencyRow(
          amountCtrl: _amountCtrl,
          currency: _currency,
          onCurrencyChanged: (v) => setState(() => _currency = v),
        ),
        const SizedBox(height: 12),
        _label('Category'),
        DropdownButtonFormField<ObligationCategory>(
          value: _category,
          decoration: const InputDecoration(isDense: true),
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          items: ObligationCategory.values
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.emoji} ${c.label}'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 12),
        _label('Frequency'),
        DropdownButtonFormField<ObligationFrequency>(
          value: _frequency,
          decoration: const InputDecoration(isDense: true),
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          items: ObligationFrequency.values
              .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.label),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _frequency = v ?? _frequency),
        ),
      ],
    );
  }
}

// ── Manual income form ───────────────────────────────────────────────────────

class ManualIncomeForm extends StatefulWidget {
  final void Function(IncomeStream) onSave;
  const ManualIncomeForm({super.key, required this.onSave});

  @override
  State<ManualIncomeForm> createState() => _ManualIncomeFormState();
}

class _ManualIncomeFormState extends State<ManualIncomeForm> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  IncomeCategory _category = IncomeCategory.other;
  ObligationFrequency _frequency = ObligationFrequency.monthly;
  String _currency = 'USD';
  bool _isOneTime = false;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) return;
    widget.onSave(IncomeStream(
      title: title,
      category: _category,
      amount: amount,
      currency: _currency,
      frequency: _frequency,
      isOneTime: _isOneTime,
      date: _isOneTime ? _date : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: '💰 Add Income',
      onSave: _save,
      saveLabel: 'Save Income',
      children: [
        _label('Title *'),
        TextField(
          controller: _titleCtrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: _isOneTime
                ? 'e.g. App Dev project, Chalet booking'
                : 'e.g. Freelance, YouTube',
          ),
        ),
        const SizedBox(height: 12),
        // One-time toggle
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isOneTime = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_isOneTime
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: !_isOneTime
                            ? AppColors.primary
                            : AppColors.textMuted),
                  ),
                  child: Text('Recurring',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: !_isOneTime
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: !_isOneTime ? FontWeight.w600 : FontWeight.normal)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isOneTime = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isOneTime
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _isOneTime
                            ? AppColors.primary
                            : AppColors.textMuted),
                  ),
                  child: Text('One-time',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _isOneTime
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: _isOneTime ? FontWeight.w600 : FontWeight.normal)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AmountCurrencyRow(
          amountCtrl: _amountCtrl,
          currency: _currency,
          onCurrencyChanged: (v) => setState(() => _currency = v),
        ),
        const SizedBox(height: 12),
        _label('Category'),
        DropdownButtonFormField<IncomeCategory>(
          value: _category,
          decoration: const InputDecoration(isDense: true),
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          items: IncomeCategory.values
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.emoji} ${c.label}'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 12),
        if (_isOneTime) ...[
          _label('Date'),
          _DatePickerField(
            date: _date,
            onChanged: (d) { if (d != null) setState(() => _date = d); },
            allowPast: true,
          ),
        ] else ...[
          _label('Frequency'),
          DropdownButtonFormField<ObligationFrequency>(
            value: _frequency,
            decoration: const InputDecoration(isDense: true),
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            items: ObligationFrequency.values
                .map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.label),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _frequency = v ?? _frequency),
          ),
        ],
      ],
    );
  }
}

// ── Manual expense form ──────────────────────────────────────────────────────

class ManualExpenseForm extends StatefulWidget {
  final void Function(Expense) onSave;
  const ManualExpenseForm({super.key, required this.onSave});

  @override
  State<ManualExpenseForm> createState() => _ManualExpenseFormState();
}

class _ManualExpenseFormState extends State<ManualExpenseForm> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.other;
  String _currency = 'USD';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) return;
    widget.onSave(Expense(
      title: title,
      amount: amount,
      currency: _currency,
      category: _category,
      date: _date,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: '💸 Log Expense',
      onSave: _save,
      saveLabel: 'Save Expense',
      children: [
        _label('Title *'),
        TextField(
          controller: _titleCtrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'e.g. Lunch, Uber'),
        ),
        const SizedBox(height: 12),
        _AmountCurrencyRow(
          amountCtrl: _amountCtrl,
          currency: _currency,
          onCurrencyChanged: (v) => setState(() => _currency = v),
        ),
        const SizedBox(height: 12),
        _label('Category'),
        DropdownButtonFormField<ExpenseCategory>(
          value: _category,
          decoration: const InputDecoration(isDense: true),
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          items: ExpenseCategory.values
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.emoji} ${c.label}'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 12),
        _label('Date'),
        _DatePickerField(
          date: _date,
          onChanged: (d) {
            if (d != null) setState(() => _date = d);
          },
          allowPast: true,
        ),
      ],
    );
  }
}

// ── Shared form helpers ──────────────────────────────────────────────────────

class _FormShell extends StatelessWidget {
  final String title;
  final VoidCallback onSave;
  final String saveLabel;
  final List<Widget> children;
  const _FormShell({
    required this.title,
    required this.onSave,
    required this.saveLabel,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(saveLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountCurrencyRow extends StatelessWidget {
  final TextEditingController amountCtrl;
  final String currency;
  final void Function(String) onCurrencyChanged;
  const _AmountCurrencyRow({
    required this.amountCtrl,
    required this.currency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Amount *'),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: '0'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Currency'),
            DropdownButton<String>(
              value: currency,
              dropdownColor: AppColors.card,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              underline: const SizedBox(),
              items: ['USD', 'KGS'].map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  )).toList(),
              onChanged: (v) => onCurrencyChanged(v ?? 'USD'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final void Function(DateTime?) onChanged;
  final bool allowPast;
  const _DatePickerField({
    required this.date,
    required this.onChanged,
    this.allowPast = false,
  });

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
              colorScheme:
                  const ColorScheme.dark(primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textMuted),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              date != null
                  ? '${date!.month}/${date!.day}/${date!.year}'
                  : 'Set date',
              style: TextStyle(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12)),
    );
