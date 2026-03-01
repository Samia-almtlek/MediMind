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
  final List<String> intakeTimes;
  // 🆕 STOCK FIELDS
  final int initialStock;
  final int currentStock;
  final int lowStockThresholdDays;
  final DateTime? lastStockAlertAt;

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
    required this.intakeTimes,
    // 🆕
    required this.initialStock,
    required this.currentStock,
    this.lowStockThresholdDays = 3,
    this.lastStockAlertAt,
  });
}
