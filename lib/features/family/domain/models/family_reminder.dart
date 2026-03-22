import 'package:uuid/uuid.dart';

enum ReminderType { birthday, call, visit, custom, followUp, anniversary, checkIn }

enum RecurrenceType { none, daily, weekly, monthly, yearly }

extension ReminderTypeLabel on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.birthday: return 'Birthday';
      case ReminderType.call: return 'Call';
      case ReminderType.visit: return 'Visit';
      case ReminderType.custom: return 'Custom';
      case ReminderType.followUp: return 'Follow Up';
      case ReminderType.anniversary: return 'Anniversary';
      case ReminderType.checkIn: return 'Check In';
    }
  }

  String get emoji {
    switch (this) {
      case ReminderType.birthday: return '🎂';
      case ReminderType.call: return '📞';
      case ReminderType.visit: return '🏠';
      case ReminderType.custom: return '📝';
      case ReminderType.followUp: return '🔄';
      case ReminderType.anniversary: return '💕';
      case ReminderType.checkIn: return '👋';
    }
  }
}

class FamilyReminder {
  final String id;
  final String personId;
  final String title;
  final String? description;
  final ReminderType reminderType;
  final DateTime dueAt;
  bool isCompleted;
  final RecurrenceType recurrenceType;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? completedAt;

  FamilyReminder({
    String? id,
    required this.personId,
    required this.title,
    this.description,
    required this.reminderType,
    required this.dueAt,
    this.isCompleted = false,
    this.recurrenceType = RecurrenceType.none,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isOverdue =>
      !isCompleted && dueAt.isBefore(DateTime.now());

  bool get isDueToday {
    final now = DateTime.now();
    return !isCompleted &&
        dueAt.year == now.year &&
        dueAt.month == now.month &&
        dueAt.day == now.day;
  }

  bool get isDueSoon =>
      !isCompleted &&
      dueAt.isAfter(DateTime.now()) &&
      dueAt.difference(DateTime.now()).inDays <= 3;

  /// Next due date for recurring reminders
  DateTime? nextRecurringDate() {
    if (recurrenceType == RecurrenceType.none) return null;
    final base = dueAt;
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return base.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return base.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(base.year, base.month + 1, base.day);
      case RecurrenceType.yearly:
        return DateTime(base.year + 1, base.month, base.day);
      case RecurrenceType.none:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'title': title,
        'description': description,
        'reminderType': reminderType.name,
        'dueAt': dueAt.toIso8601String(),
        'isCompleted': isCompleted,
        'recurrenceType': recurrenceType.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory FamilyReminder.fromJson(Map<String, dynamic> j) => FamilyReminder(
        id: j['id'],
        personId: j['personId'],
        title: j['title'],
        description: j['description'],
        reminderType: ReminderType.values.firstWhere(
          (e) => e.name == j['reminderType'],
          orElse: () => ReminderType.custom,
        ),
        dueAt: DateTime.parse(j['dueAt']),
        isCompleted: j['isCompleted'] ?? false,
        recurrenceType: RecurrenceType.values.firstWhere(
          (e) => e.name == j['recurrenceType'],
          orElse: () => RecurrenceType.none,
        ),
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'])
            : null,
      );

  factory FamilyReminder.fromRow(Map<String, dynamic> r) => FamilyReminder(
        id: r['id'],
        personId: r['person_id'] ?? '',
        title: r['title'] ?? '',
        description: r['description'],
        reminderType: ReminderType.values.firstWhere(
          (e) => e.name == r['reminder_type'],
          orElse: () => ReminderType.custom,
        ),
        dueAt: DateTime.parse(r['due_at']),
        isCompleted: r['is_completed'] ?? false,
        recurrenceType: RecurrenceType.values.firstWhere(
          (e) => e.name == r['recurrence_type'],
          orElse: () => RecurrenceType.none,
        ),
        createdAt: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(r['updated_at'] ?? '') ?? DateTime.now(),
        completedAt: r['completed_at'] != null
            ? DateTime.tryParse(r['completed_at'])
            : null,
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'person_id': personId,
        'title': title,
        'description': description,
        'reminder_type': reminderType.name,
        'due_at': dueAt.toIso8601String(),
        'is_completed': isCompleted,
        'recurrence_type': recurrenceType.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };
}
