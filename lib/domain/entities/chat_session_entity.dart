class ChatSessionEntity {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? title;

  const ChatSessionEntity({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.lastMessageAt,
    this.title,
  });
}
