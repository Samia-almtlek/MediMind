import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/medicatie_schema_entity.dart';

class MedicatieSchemaModel extends MedicatieSchemaEntity {
  const MedicatieSchemaModel({
    required super.id,
    required super.userMedicationId,
    required super.frequencyPerDay,
    required super.intakeTimes,
    required super.startDate,
    super.endDate,
    required super.isActive,
  });

  /// Convert Firestore document → Model
  factory MedicatieSchemaModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    return MedicatieSchemaModel(
      id: doc.id,
      userMedicationId: data['userMedicationId'],
      frequencyPerDay: data['frequencyPerDay'],
      intakeTimes: List<String>.from(data['intakeTimes']),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert Entity → Model
  factory MedicatieSchemaModel.fromEntity(
      MedicatieSchemaEntity entity) {
    return MedicatieSchemaModel(
      id: entity.id,
      userMedicationId: entity.userMedicationId,
      frequencyPerDay: entity.frequencyPerDay,
      intakeTimes: entity.intakeTimes,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isActive: entity.isActive,
    );
  }

  /// Convert Model → Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userMedicationId': userMedicationId,
      'frequencyPerDay': frequencyPerDay,
      'intakeTimes': intakeTimes,
      'startDate': Timestamp.fromDate(startDate),
      'endDate':
          endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
    };
  }
}
