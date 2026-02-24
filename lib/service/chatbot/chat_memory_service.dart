import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMemoryService {
  ChatMemoryService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('chat_sessions');
  CollectionReference<Map<String, dynamic>> get _messages =>
      _firestore.collection('chat_messages');

  Future<String> ensureSessionId() async {
    final userId = _auth.currentUser?.uid ?? 'anonymous';

    final existing = await _sessions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final now = Timestamp.now();
    final created = await _sessions.add({
      'userId': userId,
      'createdAt': now,
      'lastMessageAt': now,
      'title': 'MediMind Chat',
      'summary': '',
      'summaryUpdatedAt': now,
    });

    return created.id;
  }

  Future<void> saveMessage({
    required String sessionId,
    required String sender,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final now = Timestamp.now();

    await _messages.add({
      'sessionId': sessionId,
      'sender': sender,
      'content': trimmed,
      'timestamp': now,
    });

    await _sessions.doc(sessionId).set(
      {
        'lastMessageAt': now,
      },
      SetOptions(merge: true),
    );
  }

  Future<String> buildConversationContext(
    String sessionId, {
    int maxMessages = 8,
  }) async {
    final sessionDoc = await _sessions.doc(sessionId).get();
    final sessionData = sessionDoc.data();
    final summary = (sessionData?['summary'] as String?)?.trim() ?? '';

    final query = await _messages
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: true)
        .limit(maxMessages)
        .get();

    final recent = query.docs.reversed.toList();

    final lines = <String>[];

    if (summary.isNotEmpty) {
      lines.add('SESSION_SUMMARY: $summary');
    }

    if (recent.isNotEmpty) {
      lines.add('RECENT_TURNS:');
      for (final doc in recent) {
        final data = doc.data();
        final senderRaw = (data['sender'] as String?)?.toLowerCase().trim();
        final content = (data['content'] as String?)?.trim();

        if (content == null || content.isEmpty) {
          continue;
        }

        final role = senderRaw == 'user' ? 'USER' : 'ASSISTANT';
        lines.add('- $role: $content');
      }
    }

    return lines.join('\n');
  }

  Future<void> updateSummary({
    required String sessionId,
    required String userMessage,
    required String assistantMessage,
    int maxLength = 1200,
  }) async {
    final sessionDoc = await _sessions.doc(sessionId).get();
    final sessionData = sessionDoc.data();
    final existingSummary = (sessionData?['summary'] as String?)?.trim() ?? '';

    final nextChunk =
        'USER: ${userMessage.trim()} | ASSISTANT: ${assistantMessage.trim()}';

    final merged = existingSummary.isEmpty
        ? nextChunk
        : '$existingSummary\n$nextChunk';

    final bounded = merged.length <= maxLength
        ? merged
        : merged.substring(merged.length - maxLength);

    await _sessions.doc(sessionId).set(
      {
        'summary': bounded,
        'summaryUpdatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }
}
