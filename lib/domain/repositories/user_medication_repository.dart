import '../entities/user_medication_entity.dart';

abstract class UserMedicationRepository {
  Future<void> addUserMedication(UserMedicationEntity medication);

  Future<List<UserMedicationEntity>> getUserMedications(String userId);

  Future<void> deactivateMedication(String medicationId);
}
