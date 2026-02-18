import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {

  const ChatMessageModel({
    required super.id,
    required super.sessionId,
    required super.content,
    required super.sender,
    required super.timestamp,
  });

  /// Convert Firestore document → Model
  factory ChatMessageModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {

    final data = doc.data();

    return ChatMessageModel(
      id: doc.id,
      sessionId: data['sessionId'],
      content: data['content'],
      sender: data['sender'] == 'user'
          ? MessageSender.user
          : MessageSender.bot,
      timestamp:
          (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Convert Entity → Model
  factory ChatMessageModel.fromEntity(
      ChatMessageEntity entity) {

    return ChatMessageModel(
      id: entity.id,
      sessionId: entity.sessionId,
      content: entity.content,
      sender: entity.sender,
      timestamp: entity.timestamp,
    );
  }

  /// Convert Model → Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'content': content,
      'sender':
          sender == MessageSender.user ? 'user' : 'bot',
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
