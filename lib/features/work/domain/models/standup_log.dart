class StandupLog {
  final String id;
  DateTime date;
  String wins;
  String challenges;
  String priorities;
  String aiResponse;

  StandupLog({
    required this.id,
    DateTime? date,
    this.wins = '',
    this.challenges = '',
    this.priorities = '',
    this.aiResponse = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'wins': wins,
        'challenges': challenges,
        'priorities': priorities,
        'aiResponse': aiResponse,
      };

  factory StandupLog.fromJson(Map<String, dynamic> j) => StandupLog(
        id: j['id'],
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        wins: j['wins'] ?? '',
        challenges: j['challenges'] ?? '',
        priorities: j['priorities'] ?? '',
        aiResponse: j['aiResponse'] ?? '',
      );

  factory StandupLog.fromRow(Map<String, dynamic> r) => StandupLog(
        id: r['id'],
        date: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
        wins: r['wins'] ?? '',
        challenges: r['challenges'] ?? '',
        priorities: r['priorities'] ?? '',
        aiResponse: r['ai_response'] ?? '',
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'wins': wins,
        'challenges': challenges,
        'priorities': priorities,
        'ai_response': aiResponse,
        'created_at': date.toIso8601String(),
      };
}
