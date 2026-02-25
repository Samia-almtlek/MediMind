import '../entities/caregiver_entity.dart';

abstract class CaregiverRepository {
  Future<List<CaregiverEntity>> getCaregiversByUser(String userId);
  Future<void> addCaregiver(CaregiverEntity caregiver);
  Future<void> deactivateCaregiver(String caregiverId);
}
