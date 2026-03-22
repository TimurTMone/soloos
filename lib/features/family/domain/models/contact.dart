class Contact {
  final String id;
  String name;
  String emoji;
  DateTime birthday;
  String relationship;
  String notes;

  Contact({
    required this.id,
    required this.name,
    this.emoji = '👤',
    required this.birthday,
    this.relationship = 'friend',
    this.notes = '',
  });

  int get daysUntilBirthday {
    final now = DateTime.now();
    final next = DateTime(now.year, birthday.month, birthday.day);
    final diff = next.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff < 0 ? diff + 365 : diff;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'birthday': birthday.toIso8601String(),
        'relationship': relationship,
        'notes': notes,
      };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        id: j['id'],
        name: j['name'],
        emoji: j['emoji'] ?? '👤',
        birthday: DateTime.parse(j['birthday']),
        relationship: j['relationship'] ?? 'friend',
        notes: j['notes'] ?? '',
      );

  factory Contact.fromRow(Map<String, dynamic> r) => Contact(
        id: r['id'],
        name: r['name'],
        emoji: r['emoji'] ?? '👤',
        birthday: DateTime.parse(r['birthday']),
        relationship: r['relationship'] ?? 'friend',
        notes: r['notes'] ?? '',
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'birthday': birthday.toIso8601String(),
        'relationship': relationship,
        'notes': notes,
      };
}
