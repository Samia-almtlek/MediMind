import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dose_log_entity.dart';

class DoseLogModel extends DoseLogEntity {
  const DoseLogModel({
    required super.id,
    required super.medicatieId,
    required super.geplandeTijd,
    super.ingenomenTijd,
    required super.status,
    required super.escalatieVerzonden,
  });

  factory DoseLogModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    return DoseLogModel(
      id: doc.id,
      medicatieId: data['medicatieId'],
      geplandeTijd: (data['geplandeTijd'] as Timestamp).toDate(),
      ingenomenTijd: data['ingenomenTijd'] != null
          ? (data['ingenomenTijd'] as Timestamp).toDate()
          : null,
      status: data['status'],
      escalatieVerzonden: data['escalatieVerzonden'] ?? false,
    );
  }

  factory DoseLogModel.fromEntity(DoseLogEntity entity) {
    return DoseLogModel(
      id: entity.id,
      medicatieId: entity.medicatieId,
      geplandeTijd: entity.geplandeTijd,
      ingenomenTijd: entity.ingenomenTijd,
      status: entity.status,
      escalatieVerzonden: entity.escalatieVerzonden,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'medicatieId': medicatieId,
      'geplandeTijd': Timestamp.fromDate(geplandeTijd),
      'ingenomenTijd':
          ingenomenTijd != null ? Timestamp.fromDate(ingenomenTijd!) : null,
      'status': status,
      'escalatieVerzonden': escalatieVerzonden,
    };
  }
}
