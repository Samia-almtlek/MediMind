import '../entities/chat_message_entity.dart';

abstract class ChatMessageRepository {

  /// Get all messages inside a specific chat session
  Future<List<ChatMessageEntity>> getMessagesBySession(
      String sessionId);

  /// Add a new message to a session
  Future<void> sendMessage(ChatMessageEntity message);

  /// Delete a message
  Future<void> deleteMessage(String messageId);
}
