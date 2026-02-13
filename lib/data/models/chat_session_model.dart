import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_session_entity.dart';

class ChatSessionModel extends ChatSessionEntity {

  const ChatSessionModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.lastMessageAt,
    super.title,
  });

  /// Convert Firestore document → Model
  factory ChatSessionModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {

    final data = doc.data();

    return ChatSessionModel(
      id: doc.id,
      userId: data['userId'],
      createdAt:
          (data['createdAt'] as Timestamp).toDate(),
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp)
              .toDate()
          : null,
      title: data['title'],
    );
  }

  /// Convert Entity → Model
  factory ChatSessionModel.fromEntity(
      ChatSessionEntity entity) {

    return ChatSessionModel(
      id: entity.id,
      userId: entity.userId,
      createdAt: entity.createdAt,
      lastMessageAt: entity.lastMessageAt,
      title: entity.title,
    );
  }

  /// Convert Model → Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'title': title,
    };
  }
}
