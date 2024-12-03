class ChatHistory {
  final String id;
  final String title;
  final DateTime date;
  final String userId;

  ChatHistory({
    required this.id,
    required this.title,
    required this.date,
    required this.userId,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      id: json['id'],
      title: json['title'] ?? 'New Chat',
      date: DateTime.parse(json['created_at']),
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': date.toIso8601String(),
      'user_id': userId,
    };
  }
} 