import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

 
  // --- 1. MY MEDICATIONS ---
  // Returns a stream so the UI updates automatically when a med is added/removed

  Future<void> addMedication(Map<String, dynamic> medData) async {
  await _db
      .collection('users')
      .doc(uid)
      .collection('medications') // The subcollection
      .add({
        ...medData,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
  Stream<QuerySnapshot> getMedications() {
    return _db.collection('users').doc(uid).collection('medications').snapshots();
  }

  // --- 2. MEDICAL ID ---
  // Fetch current Medical ID data
  Future<DocumentSnapshot> getMedicalId() {
    return _db.collection('users').doc(uid).get();
  }

  // Update Medical ID (Blood type, Allergies, etc.)
  Future<void> updateMedicalId(Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set({
      'medical_id': data,
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- 3. NOTIFICATIONS (The "Toggle") ---
  Future<void> updateNotificationPreference(bool isEnabled) async {
    if (_uid.isEmpty) return; // Guard clause
    await _db.collection('users').doc(_uid).set({
      'settings': {'notificationsEnabled': isEnabled},
    }, SetOptions(merge: true));
  }

  // --- 4. PRIVACY & DATA ---
  // Function to request account deletion or data export log
  Future<void> requestDataExport() async {
    await _db.collection('data_requests').add({
      'userId': uid,
      'requestType': 'export_json',
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- 5. SUPPORT ---
  // Submit a help ticket
  Future<void> submitSupportTicket(String subject, String message) async {
    await _db.collection('support_tickets').add({
      'userId': uid,
      'userEmail': FirebaseAuth.instance.currentUser?.email,
      'subject': subject,
      'message': message,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}