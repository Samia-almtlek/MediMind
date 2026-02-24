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
    required super.intakeTimes,

    // 🆕 STOCK FIELDS
    required super.initialStock,
    required super.currentStock,
    super.lowStockThresholdDays = 3,
    super.lastStockAlertAt,
  });

  /// ==========================
  /// FROM FIRESTORE
  /// ==========================

  factory UserMedicationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc) {

  final data = doc.data();

  if (data == null) {
    throw Exception("UserMedication document is null: ${doc.id}");
  }

  return UserMedicationModel(
    id: doc.id,
    userId: data['userId'] ?? '',
    productId: data['productId'] ?? '',
    name: data['name'] ?? '',
    dosage: data['dosage'] ?? '',
    frequencyPerDay: data['frequencyPerDay'] ?? 1,
    startDate: data['startDate'] != null
        ? (data['startDate'] as Timestamp).toDate()
        : DateTime.now(),
    endDate: data['endDate'] != null
        ? (data['endDate'] as Timestamp).toDate()
        : null,
    instructions: data['instructions'] ?? '',
    isActive: data['isActive'] ?? true,
    aangemaaktViaOCR: data['aangemaaktViaOCR'] ?? false,
    intakeTimes: List<String>.from(data['intakeTimes'] ?? []),

    initialStock: data['initialStock'] ?? 0,
    currentStock: data['currentStock'] ?? 0,
    lowStockThresholdDays: data['lowStockThresholdDays'] ?? 3,
    lastStockAlertAt: data['lastStockAlertAt'] != null
        ? (data['lastStockAlertAt'] as Timestamp).toDate()
        : null,
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
      'intakeTimes': intakeTimes,

      // 🆕 STOCK FIELDS
      'initialStock': initialStock,
      'currentStock': currentStock,
      'lowStockThresholdDays': lowStockThresholdDays,
      'lastStockAlertAt': lastStockAlertAt != null
          ? Timestamp.fromDate(lastStockAlertAt!)
          : null,
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
      intakeTimes: entity.intakeTimes,

      // 🆕
      initialStock: entity.initialStock,
      currentStock: entity.currentStock,
      lowStockThresholdDays: entity.lowStockThresholdDays,
      lastStockAlertAt: entity.lastStockAlertAt,
    );
  }
}