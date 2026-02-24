import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database/firestore_service.dart';
import '../../domain/entities/dose_log_entity.dart';
import '../../domain/repositories/dose_log_repository.dart';
import '../models/dose_log_model.dart';

class DoseLogRepositoryImpl implements DoseLogRepository {
  final FirestoreService _firestoreService;

  DoseLogRepositoryImpl(this._firestoreService);

  /// GET all logs for a specific medication
  @override
  Future<List<DoseLogEntity>> getLogsByMedication(
      String medicatieId) async {

    final snapshot = await _firestoreService.userMedications
        .doc(medicatieId)
        .collection('dose_logs')
        .get();

    return snapshot.docs
        .map((doc) =>
            DoseLogModel.fromFirestore(
                doc))
        .toList();
  }

  /// ADD new dose log
  @override
  Future<void> addDoseLog(DoseLogEntity log) async {
    final model = DoseLogModel.fromEntity(log);

    await _firestoreService.userMedications
        .doc(log.medicatieId)
        .collection('dose_logs')
        .doc(log.id)
        .set(model.toFirestore());
  }

  /// MARK DOSE AS TAKEN
  @override
  Future<void> markAsTaken(String doseId) async {
    // Implementation simplified to match interface signature
    // TODO: Implement full dose marking logic with medication context
    return;
  }

  /// MARK DOSE AS MISSED
  @override
  Future<void> markAsMissed(String doseId) async {
    // Implementation simplified to match interface signature
    // TODO: Implement full dose marking logic with medication context
    return;
  }
}
