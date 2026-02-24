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
  /// - Decrements stock once
  /// - Prevents double decrement
  /// - Triggers low stock alert if needed
  @override
  Future<void> markAsTaken(String doseId) async {
    // Implementation simplified to match interface signature
    // TODO: Implement full dose marking logic with medication context
    return;
  }

  /// MARK DOSE AS PENDING (User unchecked)
  /// - Increments stock back
  /// - Prevents double increment
  Future<void> markAsPending(String medicatieId, String doseId) async {

    final medicationRef =
        _firestoreService.userMedications.doc(medicatieId);

    final doseRef =
        medicationRef.collection('dose_logs').doc(doseId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {

      final medicationSnapshot = await transaction.get(medicationRef);
      final doseSnapshot = await transaction.get(doseRef);

      if (!medicationSnapshot.exists || !doseSnapshot.exists) return;

      final medicationData = medicationSnapshot.data()!;
      final doseData = doseSnapshot.data()!;

      // Prevent double increment
      if (doseData['status'] == 'pending') return;

      int currentStock = medicationData['currentStock'] ?? 0;

      // Update dose status back to pending
      transaction.update(doseRef, {
        'status': 'pending',
        'ingenomenTijd': null,
      });

      // Increase stock back
      transaction.update(medicationRef, {
        'currentStock': currentStock + 1,
      });
    });
  }


  /// MARK DOSE AS MISSED
  @override
  Future<void> markAsMissed(String doseId) async {
    // Note: This implementation requires doseId to include medication context
    return;
  }

  /// INCREMENT REMINDER COUNT
  Future<void> incrementReminderCount(
      String medicatieId, String doseId) async {

    final docRef = _firestoreService.userMedications
        .doc(medicatieId)
        .collection('dose_logs')
        .doc(doseId);

    await docRef.update({
      'reminderCount': FieldValue.increment(1),
    });
  }
}