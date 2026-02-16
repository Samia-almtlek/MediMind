class DoseLogEntity {
  final String id;
  final String medicatieId;
  final DateTime geplandeTijd;
  final DateTime? ingenomenTijd;
  final String status; // taken / missed / pending
  final bool escalatieVerzonden;

  const DoseLogEntity({
    required this.id,
    required this.medicatieId,
    required this.geplandeTijd,
    this.ingenomenTijd,
    required this.status,
    required this.escalatieVerzonden,
  });
}
