import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database/firestore_service.dart';
import '../../domain/entities/caregiver_entity.dart';
import '../../domain/repositories/caregiver_repository.dart';
import '../models/caregiver_model.dart';

class CaregiverRepositoryImpl implements CaregiverRepository {
  final FirestoreService _firestoreService;

  CaregiverRepositoryImpl(this._firestoreService);

  @override
  Future<List<CaregiverEntity>> getCaregiversByUser(String userId) async {
    final snapshot = await _firestoreService.caregivers
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => CaregiverModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  @override
  Future<void> addCaregiver(CaregiverEntity caregiver) async {
    final model = CaregiverModel(
      id: caregiver.id,
      userId: caregiver.userId,
      name: caregiver.name,
      email: caregiver.email,
      relation: caregiver.relation,
      isActive: caregiver.isActive,
      addedAt: caregiver.addedAt,
    );

await _firestoreService.caregivers
      .add(model.toFirestore());  }

  @override
  Future<void> deactivateCaregiver(String caregiverId) async {
    await _firestoreService.caregivers
        .doc(caregiverId)
        .update({'isActive': false});
  }
}
