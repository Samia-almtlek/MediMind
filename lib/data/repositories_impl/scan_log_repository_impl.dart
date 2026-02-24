import '../../service/database/firestore_service.dart';
import '../../domain/entities/scan_log_entity.dart';
import '../../domain/repositories/scan_log_repository.dart';
import '../models/scan_log_model.dart';

class ScanLogRepositoryImpl implements ScanLogRepository {

  final FirestoreService _firestoreService;

  ScanLogRepositoryImpl(this._firestoreService);

  @override
  Future<void> addScanLog(ScanLogEntity log) async {

    final model = ScanLogModel.fromEntity(log);

    await _firestoreService.scanLogs
        .doc(log.id)
        .set(model.toFirestore());
  }

  @override
  Future<List<ScanLogEntity>> getUserScanLogs(
      String userId) async {

    final snapshot = await _firestoreService.scanLogs
        .where('gebruikerId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) =>
            ScanLogModel.fromFirestore(
                doc))
        .toList();
  }
}
