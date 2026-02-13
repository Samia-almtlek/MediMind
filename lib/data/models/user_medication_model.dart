import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_medication_entity.dart';

class UserMedicationModel extends UserMedicationEntity {
  const UserMedicationModel({
    required super.id,
    required super.userId,
    required super.productId,
    required super.name,
    required super.dosage,
    required super.frequencyPerDay,
    required super.startDate,
    super.endDate,
    super.instructions,
    required super.isActive,
    required super.aangemaaktViaOCR,
  });

  /// ==========================
  /// FROM FIRESTORE
  /// ==========================

  factory UserMedicationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return UserMedicationModel(
      id: doc.id,
      userId: data['userId'],
      productId: data['productId'],
      name: data['name'],
      dosage: data['dosage'],
      frequencyPerDay: data['frequencyPerDay'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      instructions: data['instructions'],
      isActive: data['isActive'],
      aangemaaktViaOCR: data['aangemaaktViaOCR'],
    );
  }

  /// ==========================
  /// TO FIRESTORE
  /// ==========================

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'name': name,
      'dosage': dosage,
      'frequencyPerDay': frequencyPerDay,
      'startDate': Timestamp.fromDate(startDate),
      'endDate':
          endDate != null ? Timestamp.fromDate(endDate!) : null,
      'instructions': instructions,
      'isActive': isActive,
      'aangemaaktViaOCR': aangemaaktViaOCR,
    };
  }

  /// ==========================
  /// FROM ENTITY
  /// ==========================

  factory UserMedicationModel.fromEntity(
      UserMedicationEntity entity) {
    return UserMedicationModel(
      id: entity.id,
      userId: entity.userId,
      productId: entity.productId,
      name: entity.name,
      dosage: entity.dosage,
      frequencyPerDay: entity.frequencyPerDay,
      startDate: entity.startDate,
      endDate: entity.endDate,
      instructions: entity.instructions,
      isActive: entity.isActive,
      aangemaaktViaOCR: entity.aangemaaktViaOCR,
    );
  }
}
