import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ==========================
  /// COLLECTION REFERENCES (TYPED)
  /// ==========================

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get products =>
      _firestore.collection('product');

  CollectionReference<Map<String, dynamic>> get scanLogs =>
      _firestore.collection('scan_logs');

  CollectionReference<Map<String, dynamic>> get searchHistory =>
      _firestore.collection('search_history');

  CollectionReference<Map<String, dynamic>> get caregivers =>
      _firestore.collection('caregivers');

  CollectionReference<Map<String, dynamic>> get userMedications =>
      _firestore.collection('user_medications');

  CollectionReference<Map<String, dynamic>> get medicatieSchema =>
      _firestore.collection('medicatie_schema');

  CollectionReference<Map<String, dynamic>> get doseLogs =>
      _firestore.collection('dose_logs');

  CollectionReference<Map<String, dynamic>> get chatSessions =>
      _firestore.collection('chat_sessions');

  CollectionReference<Map<String, dynamic>> get chatMessages =>
      _firestore.collection('chat_messages');

  /// ==========================
  /// GENERIC HELPERS
  /// ==========================

  Future<void> setDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await collection.doc(docId).set(data);
  }

  Future<void> addDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, dynamic> data,
  }) async {
    await collection.add(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required String docId,
  }) async {
    return await collection.doc(docId).get();
  }

  Future<void> deleteDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required String docId,
  }) async {
    await collection.doc(docId).delete();
  }
}
