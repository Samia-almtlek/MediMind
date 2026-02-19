import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database/firestore_service.dart';
import '../../domain/entities/dose_log_entity.dart';
import '../../domain/repositories/dose_log_repository.dart';
import '../models/dose_log_model.dart';

class DoseLogRepositoryImpl implements DoseLogRepository {
  final FirestoreService _firestoreService;

  DoseLogRepositoryImpl(this._firestoreService);

  @override
  Future<List<DoseLogEntity>> getLogsByMedication(
      String medicatieId) async {
    final snapshot = await _firestoreService.doseLogs
        .where('medicatieId', isEqualTo: medicatieId)
        .get();

    return snapshot.docs
        .map((doc) =>
            DoseLogModel.fromFirestore(
                doc))
        .toList();
  }

  @override
  Future<void> addDoseLog(DoseLogEntity log) async {
    final model = DoseLogModel.fromEntity(log);

    await _firestoreService.doseLogs.add(
      model.toFirestore(),
    );
  }

  @override
  Future<void> markAsTaken(String doseId) async {
    await _firestoreService.doseLogs
        .doc(doseId)
        .update({
      'status': 'taken',
      'ingenomenTijd': Timestamp.now(),
    });
  }

  @override
  Future<void> markAsMissed(String doseId) async {
    await _firestoreService.doseLogs
        .doc(doseId)
        .update({
      'status': 'missed',
    });
  }
}
