import '../../service/database/firestore_service.dart';
import '../../domain/entities/user_medication_entity.dart';
import '../../domain/repositories/user_medication_repository.dart';
import '../models/user_medication_model.dart';

class UserMedicationRepositoryImpl implements UserMedicationRepository {
  final FirestoreService _firestoreService;

  UserMedicationRepositoryImpl(this._firestoreService);

  @override
  Future<void> addUserMedication(UserMedicationEntity medication) async {
    await _firestoreService.userMedications.doc(medication.id).set(
          UserMedicationModel.fromEntity(medication).toFirestore(),
        );
  }

  @override
  Future<List<UserMedicationEntity>> getUserMedications(String userId) async {
    final snapshot = await _firestoreService.userMedications
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => UserMedicationModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> deactivateMedication(String medicationId) async {
    await _firestoreService.userMedications
        .doc(medicationId)
        .update({'isActive': false});
  }
}
