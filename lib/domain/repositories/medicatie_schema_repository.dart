import '../entities/medicatie_schema_entity.dart';

abstract class MedicatieSchemaRepository {

  /// Get all schedules for a specific medication
  Future<List<MedicatieSchemaEntity>> getSchemasByMedication(
      String userMedicationId);

  /// Create a new medication schedule
  Future<void> createSchema(MedicatieSchemaEntity schema);

  /// Update an existing schedule
  Future<void> updateSchema(MedicatieSchemaEntity schema);

  /// Delete a schedule
  Future<void> deleteSchema(String schemaId);
}
