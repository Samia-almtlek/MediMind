import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database/firestore_service.dart';
import '../../domain/entities/chat_session_entity.dart';
import '../../domain/repositories/chat_session_repository.dart';
import '../models/chat_session_model.dart';

class ChatSessionRepositoryImpl
    implements ChatSessionRepository {

  final FirestoreService _firestoreService;

  ChatSessionRepositoryImpl(this._firestoreService);

  @override
  Future<void> createSession(
      ChatSessionEntity session) async {

    final model =
        ChatSessionModel.fromEntity(session);

    await _firestoreService.chatSessions
        .doc(session.id)
        .set(model.toFirestore());
  }

  @override
  Future<List<ChatSessionEntity>> getUserSessions(
      String userId) async {

    final snapshot = await _firestoreService.chatSessions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) =>
            ChatSessionModel.fromFirestore(
                doc))
        .toList();
  }

  @override
  Future<void> deleteSession(
      String sessionId) async {

    await _firestoreService.chatSessions
        .doc(sessionId)
        .delete();
  }
}
