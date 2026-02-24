import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/repositories_impl/dose_log_repository_impl.dart';
import '../../domain/entities/user_medication_entity.dart';
import '../../domain/entities/dose_log_entity.dart';
import '../database/firestore_service.dart';
import '../../core/notification/notification_service.dart';

class DoseGenerationService {
  final DoseLogRepositoryImpl _doseRepository;

  DoseGenerationService()
      : _doseRepository = DoseLogRepositoryImpl(FirestoreService());

  Future<void> generateDoses(UserMedicationEntity medication) async {
    if (medication.endDate == null) return;

    final now = DateTime.now();

    // if statrtdate in past start from today
    DateTime currentDate = medication.startDate.isBefore(now)
        ? DateTime(now.year, now.month, now.day)
        : medication.startDate;

    final endDate = medication.endDate!;

    while (!currentDate.isAfter(endDate)) {
      for (String timeString in medication.intakeTimes) {
        final parts = timeString.split(":");
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final geplandeTijd = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          hour,
          minute,
        );

        final generatedId =
            FirebaseFirestore.instance.collection('temp').doc().id;

        final dose = DoseLogEntity(
  id: generatedId,
  userId: medication.userId,
  medicatieId: medication.id,
  medicatieNaam: medication.name,
  geplandeTijd: geplandeTijd,
  status: "pending",
  ingenomenTijd: null,
  reminderCount: 0,
  escalatieVerzonden: false,
  scheduledNotificationIds: [],
);

       
        await _doseRepository.addDoseLog(dose);

        // just if in the future 
        if (geplandeTijd.isAfter(now)) {
          print("✅ Scheduling notification at $geplandeTijd");

          final baseNotificationId = generatedId.hashCode.abs();

          await NotificationService.instance.scheduleDoseWithReminderLoop(
  medicatieId: medication.id,
  doseId: generatedId,
  baseId: baseNotificationId,
  scheduledTime: geplandeTijd,
  medicationName: medication.name,
);
        } else {
          print("⛔ Skipping past dose: $geplandeTijd");
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }
}