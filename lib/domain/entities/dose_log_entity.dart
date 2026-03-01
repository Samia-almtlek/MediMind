import 'package:cloud_firestore/cloud_firestore.dart';

class DoseLogEntity {
  final String id;
  final String userId;
  final String medicatieId;
  final String medicatieNaam;

  final DateTime geplandeTijd;
  final DateTime? ingenomenTijd;

  final String status; // pending | taken | missed

  final int reminderCount;
  final bool escalatieVerzonden;
  final DateTime? escalatieTijd;

  final List<int> scheduledNotificationIds;

  final DocumentReference<Map<String, dynamic>>? reference;

  const DoseLogEntity({
    required this.id,
    required this.userId,
    required this.medicatieId,
    required this.medicatieNaam,
    required this.geplandeTijd,
    this.ingenomenTijd,
    required this.status,
    this.reminderCount = 0,
    this.escalatieVerzonden = false,
    this.escalatieTijd,
    this.scheduledNotificationIds = const [],
    this.reference,
  });
}