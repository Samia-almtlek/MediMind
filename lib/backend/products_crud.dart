import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductsCrud {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Future<void> addProduct(
  //     String productName, String dosage, String note, String barcode) async {
  //   await _db
  //       .collection('users')
  //       .doc(uid)
  //       .collection('products') // The subcollection
  //       .add({
  //     'productName': productName,
  //     'dosage': dosage,
  //     'note': note,
  //     'barcode': barcode,
  //     'createdAt': FieldValue.serverTimestamp(),
  //   });
  // }

  Future<void> addMedication({
    required String name,
    required String dosage,
    required String? notes,
    required int frequency,
    required int durationDays,
    required List<String> intakeTimes,
    required DateTime endDate,
  }) async {
    if (uid == null) return;

    await _db
        .collection('user_medications') // Changed to 'medications' for clarity
        .add({
      'name': name,
      'dosage': dosage,
      'notes': notes,
      'frequency': frequency,
      'durationDays': durationDays,
      'intakeTimes': intakeTimes, // Stores as ["08:00 AM", "08:00 PM"]
      'endDate': endDate,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': _uid, // Associate medication with the user
    });
  }
}
