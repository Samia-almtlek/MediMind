import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dose_log_entity.dart';
class DoseLogModel extends DoseLogEntity {
  const DoseLogModel({
    required super.id,
    required super.userId,
    required super.medicatieId,
    required super.medicatieNaam,
    required super.geplandeTijd,
    super.ingenomenTijd,
    required super.status,
    required super.reminderCount,
    required super.escalatieVerzonden,
    super.escalatieTijd,
    required super.scheduledNotificationIds,
    super.takenAmountValue,
    super.takenAmountUnit,
    super.takenAmountText,
    super.source,
    required super.reference,
  });

  factory DoseLogModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    return DoseLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      medicatieId: data['medicatieId'] ?? '',
      medicatieNaam: data['medicatieNaam'] ?? '',
      geplandeTijd: (data['geplandeTijd'] as Timestamp).toDate(),
      ingenomenTijd: data['ingenomenTijd'] != null
          ? (data['ingenomenTijd'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pending',
      reminderCount: data['reminderCount'] ?? 0,
      escalatieVerzonden: data['escalatieVerzonden'] ?? false,
      escalatieTijd: data['escalatieTijd'] != null
          ? (data['escalatieTijd'] as Timestamp).toDate()
          : null,
      scheduledNotificationIds:
          List<int>.from(data['scheduledNotificationIds'] ?? []),
      takenAmountValue: _toDoubleOrNull(data['takenAmountValue']),
      takenAmountUnit: (data['takenAmountUnit'] as String?)?.trim(),
      takenAmountText: (data['takenAmountText'] as String?)?.trim(),
      source: (data['source'] as String?)?.trim(),
      reference: doc.reference,
    );
  }

  factory DoseLogModel.fromEntity(DoseLogEntity entity) {
    return DoseLogModel(
      id: entity.id,
      userId: entity.userId,
      medicatieId: entity.medicatieId,
      medicatieNaam: entity.medicatieNaam,
      geplandeTijd: entity.geplandeTijd,
      ingenomenTijd: entity.ingenomenTijd,
      status: entity.status,
      reminderCount: entity.reminderCount,
      escalatieVerzonden: entity.escalatieVerzonden,
      escalatieTijd: entity.escalatieTijd,
      scheduledNotificationIds: entity.scheduledNotificationIds,
      takenAmountValue: entity.takenAmountValue,
      takenAmountUnit: entity.takenAmountUnit,
      takenAmountText: entity.takenAmountText,
      source: entity.source,
      reference: entity.reference,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'medicatieId': medicatieId,
      'medicatieNaam': medicatieNaam,
      'geplandeTijd': Timestamp.fromDate(geplandeTijd),
      'ingenomenTijd':
          ingenomenTijd != null ? Timestamp.fromDate(ingenomenTijd!) : null,
      'status': status,
      'reminderCount': reminderCount,
      'escalatieVerzonden': escalatieVerzonden,
      'escalatieTijd':
          escalatieTijd != null ? Timestamp.fromDate(escalatieTijd!) : null,
      'scheduledNotificationIds': scheduledNotificationIds,
      'takenAmountValue': takenAmountValue,
      'takenAmountUnit': takenAmountUnit,
      'takenAmountText': takenAmountText,
      'source': source,
    };
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}