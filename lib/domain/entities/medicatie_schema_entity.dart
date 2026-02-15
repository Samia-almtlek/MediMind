class MedicatieSchemaEntity {
  final String id;

  /// Foreign key → user_medications collection
  final String userMedicationId;

  /// Number of times per day (e.g., 2x daily)
  final int frequencyPerDay;

  /// List of daily intake times (e.g., ["08:00", "20:00"])
  final List<String> intakeTimes;

  /// Start date of treatment
  final DateTime startDate;

  /// Optional end date of treatment
  final DateTime? endDate;

  /// Indicates if the schedule is currently active
  final bool isActive;

  const MedicatieSchemaEntity({
    required this.id,
    required this.userMedicationId,
    required this.frequencyPerDay,
    required this.intakeTimes,
    required this.startDate,
    this.endDate,
    required this.isActive,
  });
}
