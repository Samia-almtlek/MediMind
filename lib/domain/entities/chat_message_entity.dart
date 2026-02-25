enum MessageSender {
  user,
  bot,
}

class ChatMessageEntity {
  final String id;
  final String sessionId;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;

  const ChatMessageEntity({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.sender,
    required this.timestamp,
  });
}
