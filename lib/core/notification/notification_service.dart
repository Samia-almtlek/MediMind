import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/repositories_impl/dose_log_repository_impl.dart';
import '../../service/database/firestore_service.dart';

import '../service/tts_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final DoseLogRepositoryImpl _doseRepository =
      DoseLogRepositoryImpl(FirestoreService());

  bool _initialized = false;

  /// ==========================
  /// INIT
  /// ==========================
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
   
        final payload = response.payload;
        if (payload == null) return;

        final parts = payload.split('|');
        if (parts.length != 5) return;
        final stage = int.parse(parts[1]);
        final medicatieId = parts[2];
        final doseId = parts[3];
        final medicationName = parts[4];

        await _doseRepository.incrementReminderCount(medicatieId, doseId);

        // 🔊 Check if voice reminder is enabled
        final voiceEnabled = Hive.box('notification_settings')
            .get('voiceEnabled', defaultValue: false);

final hideSensitive =
    Hive.box('notification_settings')
        .get('hideSensitive', defaultValue: false);

        if (voiceEnabled) {
          String ttsText;

         switch (stage) {
  case 1:
    ttsText = hideSensitive
        ? "It is time to take your medication."
        : "It is time to take $medicationName.";
    break;

  case 2:
    ttsText = hideSensitive
        ? "Reminder. Please take your medication."
        : "Reminder. Please take $medicationName.";
    break;

  case 3:
    ttsText = hideSensitive
        ? "Last reminder. Please take your medication now."
        : "Last reminder. Please take $medicationName now.";
    break;

  default:
    ttsText = "Medication reminder.";
}

          await Future.delayed(const Duration(milliseconds: 400));
          await TTSService.instance.speak(ttsText);
        }

        if (stage >= 3) {
          Future.delayed(const Duration(minutes: 1), () async {
            final logs = await _doseRepository.getLogsByMedication(medicatieId);

            final dose = logs.firstWhere((element) => element.id == doseId);

            if (dose.status == "pending") {
              await _doseRepository.markAsMissed(medicatieId, doseId);
            }
          });
        }
      },
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'medication_channel',
        'Medication Reminders',
        description: 'Medication reminder notifications',
        importance: Importance.max,
      ),
    );

    await _requestPermissions();

    _initialized = true;
  }

  /// ==========================
  /// PERMISSIONS
  /// ==========================
  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// ==========================
  /// SCHEDULE DOSE LOOP (REAL TIMES)
  /// ==========================
  Future<void> scheduleDoseWithReminderLoop({
    required String medicatieId,
    required String doseId,
    required int baseId,
    required DateTime scheduledTime,
    required String medicationName,
  }) async {
    // 🔒 LOCK SCREEN PRIVACY
    final hideSensitive = Hive.box('notification_settings')
        .get('hideSensitive', defaultValue: false);

    final safeBaseId = baseId % 1000000;

    final firstTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final secondTime = tz.TZDateTime.from(
        scheduledTime.add(const Duration(minutes: 5)), tz.local);

    final thirdTime = tz.TZDateTime.from(
        scheduledTime.add(const Duration(minutes: 10)), tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_channel',
        'Medication Reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    final text1 = hideSensitive
        ? "Time to take your medication"
        : "Time to take $medicationName";

    final text2 = hideSensitive
        ? "Don't forget your medication"
        : "Don't forget to take $medicationName";

    final text3 = hideSensitive
        ? "Please take your medication now"
        : "Please take $medicationName now";

    await _notifications.zonedSchedule(
      safeBaseId,
      "Medication Reminder",
      text1,
      firstTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: "STAGE|1|$medicatieId|$doseId|$medicationName",
    );

    await _notifications.zonedSchedule(
      safeBaseId + 1,
      "Reminder",
      text2,
      secondTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: "STAGE|2|$medicatieId|$doseId|$medicationName",
    );

    await _notifications.zonedSchedule(
      safeBaseId + 2,
      "Last Reminder",
      text3,
      thirdTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: "STAGE|3|$medicatieId|$doseId|$medicationName",
    );
  }

  /// ==========================
  /// LOW STOCK ALERT
  /// ==========================
  Future<void> showLowStockAlert({
    required String medicationName,
    required int remainingDays,
  }) async {
    final hideSensitive = Hive.box('notification_settings')
        .get('hideSensitive', defaultValue: false);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_channel',
        'Medication Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final body = hideSensitive
        ? "Your medication stock is running low."
        : "$medicationName will run out in $remainingDays day(s). Please refill soon.";

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 1000000,
      "Low Medication Stock",
      body,
      details,
    );
  }
}
