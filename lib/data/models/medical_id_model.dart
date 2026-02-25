import 'package:cloud_firestore/cloud_firestore.dart';
import 'caregiver_model.dart';

class MedicalIdModel {
  final String id;
  final String userId;
  final String bloodType;
  final List<String> allergies;
  final List<CaregiverModel> caregivers; // The linked sub-collection data

  MedicalIdModel({
    required this.id,
    required this.userId,
    required this.bloodType,
    required this.allergies,
    this.caregivers = const [],
  });

  factory MedicalIdModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, 
    List<CaregiverModel> caregivers,
  ) {
    final data = doc.data()!;
    return MedicalIdModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      bloodType: data['bloodType'] ?? '',
      allergies: List<String>.from(data['allergies'] ?? []),
      caregivers: caregivers,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bloodType': bloodType,
      'allergies': allergies,
      // Caregivers are not stored here; they live in the sub-collection
    };
  }
}