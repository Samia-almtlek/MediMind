import '../../service/database/firestore_service.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_message_repository.dart';
import '../models/chat_message_model.dart';

class ChatMessageRepositoryImpl
    implements ChatMessageRepository {

  final FirestoreService _firestoreService;

  ChatMessageRepositoryImpl(this._firestoreService);

  @override
  Future<List<ChatMessageEntity>> getMessagesBySession(
      String sessionId) async {

    final snapshot = await _firestoreService.chatMessages
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp')
        .get();

    return snapshot.docs
        .map((doc) =>
            ChatMessageModel.fromFirestore(
                doc))
        .toList();
  }

  @override
  Future<void> sendMessage(
      ChatMessageEntity message) async {

    final model =
        ChatMessageModel.fromEntity(message);

    await _firestoreService.chatMessages
        .add(model.toFirestore());
  }

  @override
  Future<void> deleteMessage(
      String messageId) async {

    await _firestoreService.chatMessages
        .doc(messageId)
        .delete();
  }
}
