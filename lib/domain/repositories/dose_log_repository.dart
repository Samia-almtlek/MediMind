import '../entities/dose_log_entity.dart';

abstract class DoseLogRepository {
  Future<List<DoseLogEntity>> getLogsByMedication(String medicatieId);

  Future<void> addDoseLog(DoseLogEntity log);

  Future<void> markAsTaken(String doseId);

  Future<void> markAsMissed(String doseId);
}
