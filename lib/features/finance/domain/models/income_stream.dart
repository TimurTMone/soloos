import 'package:uuid/uuid.dart';
import 'obligation_item.dart'; // reuse ObligationFrequency

enum IncomeCategory { freelance, salary, project, youtube, sponsorship, investment, other }

extension IncomeCategoryLabel on IncomeCategory {
  String get label {
    switch (this) {
      case IncomeCategory.freelance: return 'Freelance';
      case IncomeCategory.salary: return 'Salary';
      case IncomeCategory.project: return 'Project';
      case IncomeCategory.youtube: return 'YouTube';
      case IncomeCategory.sponsorship: return 'Sponsorship';
      case IncomeCategory.investment: return 'Investment';
      case IncomeCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case IncomeCategory.freelance: return '💻';
      case IncomeCategory.salary: return '💼';
      case IncomeCategory.project: return '📂';
      case IncomeCategory.youtube: return '▶️';
      case IncomeCategory.sponsorship: return '🤝';
      case IncomeCategory.investment: return '📈';
      case IncomeCategory.other: return '💰';
    }
  }
}

class IncomeStream {
  final String id;
  final String title;
  final IncomeCategory category;
  final double amount;
  final String currency;
  final ObligationFrequency frequency;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  DateTime updatedAt;

  IncomeStream({
    String? id,
    required this.title,
    required this.category,
    required this.amount,
    this.currency = 'USD',
    this.frequency = ObligationFrequency.monthly,
    this.isActive = true,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get monthlyIncome => frequency.monthlyAmount(amount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'amount': amount,
        'currency': currency,
        'frequency': frequency.name,
        'isActive': isActive,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory IncomeStream.fromJson(Map<String, dynamic> j) => IncomeStream(
        id: j['id'],
        title: j['title'],
        category: IncomeCategory.values.firstWhere(
          (e) => e.name == j['category'],
          orElse: () => IncomeCategory.other,
        ),
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] ?? 'USD',
        frequency: ObligationFrequency.values.firstWhere(
          (e) => e.name == j['frequency'],
          orElse: () => ObligationFrequency.monthly,
        ),
        isActive: j['isActive'] ?? true,
        notes: j['notes'],
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
      );
}
