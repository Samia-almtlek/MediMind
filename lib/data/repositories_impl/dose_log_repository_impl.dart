import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database/firestore_service.dart';
import '../../domain/entities/dose_log_entity.dart';
import '../../domain/repositories/dose_log_repository.dart';
import '../models/dose_log_model.dart';
import '../../core/notification/notification_service.dart';

class DoseLogRepositoryImpl implements DoseLogRepository {
  final FirestoreService _firestoreService;

  DoseLogRepositoryImpl(this._firestoreService);

  /// ============================================
  /// GET all logs for a specific medication
  /// ============================================
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

  /// ============================================
  /// ADD new dose log
  /// ============================================
  @override
  Future<void> addDoseLog(DoseLogEntity log) async {
    final model = DoseLogModel.fromEntity(log);

    await _firestoreService.userMedications
        .doc(log.medicatieId)
        .collection('dose_logs')
        .doc(log.id)
        .set(model.toFirestore());
  }

  /// ============================================
  /// MARK DOSE AS TAKEN
  /// - Decrements stock once
  /// - Prevents double decrement
  /// - Triggers low stock alert if needed
  /// ============================================
  @override
  Future<void> markAsTaken(String medicatieId, String doseId) async {

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

      // Prevent double-taking
      if (doseData['status'] == 'taken') return;

      int currentStock = medicationData['currentStock'] ?? 0;
      int frequencyPerDay = medicationData['frequencyPerDay'] ?? 1;
      int thresholdDays = medicationData['lowStockThresholdDays'] ?? 3;
      Timestamp? lastAlertTs = medicationData['lastStockAlertAt'];

      DateTime? lastAlert =
          lastAlertTs != null ? lastAlertTs.toDate() : null;

      if (currentStock <= 0) return;

      // Update dose status
      transaction.update(doseRef, {
        'status': 'taken',
        'ingenomenTijd': Timestamp.now(),
      });

      // Decrement stock safely
      currentStock--;

      if (currentStock < 0) currentStock = 0;

      transaction.update(medicationRef, {
        'currentStock': currentStock,
      });

      // Calculate remaining days
      double remainingDaysDouble =
          currentStock / frequencyPerDay;
      int remainingDays = remainingDaysDouble.floor();

      // 24h anti-spam cooldown
      bool canSendAlert = true;
      if (lastAlert != null) {
        final difference =
            DateTime.now().difference(lastAlert);
        if (difference.inHours < 24) {
          canSendAlert = false;
        }
      }

      // Trigger low stock alert if needed
      if (remainingDays <= thresholdDays && canSendAlert) {
        Future.microtask(() async {
          await NotificationService.instance.showLowStockAlert(
            medicationName: medicationData['name'],
            remainingDays: remainingDays,
          );

          await medicationRef.update({
            'lastStockAlertAt': Timestamp.now(),
          });
        });
      }
    });
  }

  /// ============================================
  /// MARK DOSE AS PENDING (User unchecked)
  /// - Increments stock back
  /// - Prevents double increment
  /// ============================================
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

  /// ============================================
  /// MARK DOSE AS MISSED
  /// ============================================
  @override
  Future<void> markAsMissed(String medicatieId, String doseId) async {
    await _firestoreService.userMedications
        .doc(medicatieId)
        .collection('dose_logs')
        .doc(doseId)
        .update({
      'status': 'missed',
    });
  }

  /// ============================================
  /// INCREMENT REMINDER COUNT
  /// ============================================
  @override
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