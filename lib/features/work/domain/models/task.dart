class Task {
  final String id;
  String title;
  String notes;
  bool isDone;
  String priority; // high, medium, low
  DateTime? dueDate;
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.isDone = false,
    this.priority = 'medium',
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'isDone': isDone,
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'],
        title: j['title'],
        notes: j['notes'] ?? '',
        isDone: j['isDone'] ?? false,
        priority: j['priority'] ?? 'medium',
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate']) : null,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );

  /// Supabase row → Task
  factory Task.fromRow(Map<String, dynamic> r) => Task(
        id: r['id'],
        title: r['title'],
        notes: r['notes'] ?? '',
        isDone: r['is_done'] ?? false,
        priority: r['priority'] ?? 'medium',
        dueDate: r['due_date'] != null ? DateTime.tryParse(r['due_date']) : null,
        createdAt: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
      );

  /// Task → Supabase row (excludes user_id — added by SupabaseService)
  Map<String, dynamic> toRow(String projectId) => {
        'id': id,
        'project_id': projectId,
        'title': title,
        'notes': notes,
        'is_done': isDone,
        'priority': priority,
        'due_date': dueDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
