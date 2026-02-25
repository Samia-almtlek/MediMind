import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/caregiver_entity.dart';

class CaregiverModel extends CaregiverEntity {
  const CaregiverModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.email,
    required super.relation,
    required super.isActive,
    super.addedAt,
  });

  factory CaregiverModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CaregiverModel.fromMap(data, doc.id);
  }

  factory CaregiverModel.fromMap(Map<String, dynamic> data, String id) {
    return CaregiverModel(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      relation: data['relation'] ?? '',
      isActive: data['isActive'] ?? false,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'relation': relation,
      'isActive': isActive,
      'addedAt': addedAt ?? FieldValue.serverTimestamp(),
    };
  }
}
