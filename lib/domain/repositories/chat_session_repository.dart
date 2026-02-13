import '../entities/chat_session_entity.dart';

abstract class ChatSessionRepository {

  /// Create a new chat session
  Future<void> createSession(ChatSessionEntity session);

  /// Get all sessions for a specific user
  Future<List<ChatSessionEntity>> getUserSessions(String userId);

  /// Delete a chat session
  Future<void> deleteSession(String sessionId);
}
