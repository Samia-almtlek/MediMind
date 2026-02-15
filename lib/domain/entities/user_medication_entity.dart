class UserMedicationEntity {
  final String id;
  final String userId;
  final String productId;
  final String name;
  final String dosage;
  final int frequencyPerDay;
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;
  final bool isActive;
  final bool aangemaaktViaOCR;

  const UserMedicationEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.name,
    required this.dosage,
    required this.frequencyPerDay,
    required this.startDate,
    this.endDate,
    this.instructions,
    required this.isActive,
    required this.aangemaaktViaOCR,
  });
}
