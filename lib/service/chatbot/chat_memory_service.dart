import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String _refusalMarker =
  'cannot answer this question with certainty';

class ChatMemoryMessage {
  const ChatMemoryMessage({
    required this.isUser,
    required this.content,
    required this.time,
  });

  final bool isUser;
  final String content;
  final DateTime time;
}

class ChatMemoryService {
  ChatMemoryService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static String? _activeSessionId;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('chat_sessions');
  CollectionReference<Map<String, dynamic>> get _messages =>
      _firestore.collection('chat_messages');

  Future<String> ensureSessionId() async {
    final existingActiveSessionId = _activeSessionId;
    if (existingActiveSessionId != null && existingActiveSessionId.isNotEmpty) {
      return existingActiveSessionId;
    }

    final userId = _auth.currentUser?.uid ?? 'anonymous';
    final createdSessionId = await _createSession(userId);
    _activeSessionId = createdSessionId;
    return createdSessionId;
  }

  Future<String> _createSession(String userId) async {
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
      .limit(maxMessages * 4)
        .get();

    final sorted = query.docs.toList()
      ..sort((a, b) {
      final aTs = a.data()['timestamp'];
      final bTs = b.data()['timestamp'];
      final aDate = aTs is Timestamp
        ? aTs.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = bTs is Timestamp
        ? bTs.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
      });

    final trimmedDescending =
      sorted.length <= maxMessages ? sorted : sorted.take(maxMessages).toList();
    final recent = trimmedDescending.reversed.toList();

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
    final sanitizedSummary = _removeRefusalEntries(existingSummary);

    if (_isRefusal(assistantMessage)) {
      await _sessions.doc(sessionId).set(
        {
          'summary': sanitizedSummary,
          'summaryUpdatedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    final nextChunk =
        'USER: ${userMessage.trim()} | ASSISTANT: ${assistantMessage.trim()}';

    final merged = sanitizedSummary.isEmpty
        ? nextChunk
        : '$sanitizedSummary\n$nextChunk';

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

  bool _isRefusal(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains(_refusalMarker);
  }

  String _removeRefusalEntries(String summary) {
    if (summary.trim().isEmpty) {
      return '';
    }

    final lines = summary
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final kept = <String>[];
    for (final line in lines) {
      if (_isRefusal(line)) {
        continue;
      }
      kept.add(line);
    }

    return kept.join('\n');
  }

  Future<List<ChatMemoryMessage>> getSessionMessages(
    String sessionId, {
    int maxMessages = 80,
  }) async {
    final query = await _messages
        .where('sessionId', isEqualTo: sessionId)
        .limit(maxMessages * 4)
        .get();

    final sorted = query.docs.toList()
      ..sort((a, b) {
        final aTs = a.data()['timestamp'];
        final bTs = b.data()['timestamp'];
        final aDate = aTs is Timestamp
            ? aTs.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = bTs is Timestamp
            ? bTs.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

    final docs = sorted.length <= maxMessages
        ? sorted
        : sorted.sublist(sorted.length - maxMessages);
    final messages = <ChatMemoryMessage>[];

    for (final doc in docs) {
      final data = doc.data();
      final content = (data['content'] as String?)?.trim();
      final sender = (data['sender'] as String?)?.toLowerCase().trim();
      final timestamp = data['timestamp'];

      if (content == null || content.isEmpty) {
        continue;
      }

      final createdAt =
          timestamp is Timestamp ? timestamp.toDate() : DateTime.now();

      messages.add(
        ChatMemoryMessage(
          isUser: sender == 'user',
          content: content,
          time: createdAt,
        ),
      );
    }

    return messages;
  }
}
