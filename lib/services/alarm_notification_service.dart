import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import '../models/alarm_model.dart';

class AlarmNotificationService {
  static final AlarmNotificationService _instance =
      AlarmNotificationService._internal();
  factory AlarmNotificationService() => _instance;
  AlarmNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _initialized = false;

  // Callback for when alarm notification is triggered
  Function(String)? onAlarmTriggered;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // When user taps on notification or notification appears
        if (details.payload != null) {
          debugPrint('Alarm notification triggered: ${details.payload}');
          onAlarmTriggered?.call(details.payload!);
          // Play alarm sound immediately
          _playAlarmSound();
        }
      },
    );

    // Request permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) return;

    // Cancel existing alarm with this ID
    await cancelAlarm(alarm.id);

    final now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'alarm.mp3',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (alarm.repeatDays.isEmpty) {
      // One-time alarm
      await _notifications.zonedSchedule(
        int.parse(alarm.id),
        'Alarm: ${alarm.label}',
        alarm.formattedTime,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: alarm.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else {
      // Repeating alarm - schedule for each selected day
      for (final day in alarm.repeatDays) {
        DateTime nextAlarmDate = scheduledDate;

        // Find the next occurrence of this weekday
        while (nextAlarmDate.weekday % 7 != day) {
          nextAlarmDate = nextAlarmDate.add(const Duration(days: 1));
        }

        await _notifications.zonedSchedule(
          int.parse(alarm.id) + day, // Unique ID for each day
          'Alarm: ${alarm.label}',
          alarm.formattedTime,
          tz.TZDateTime.from(nextAlarmDate, tz.local),
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: alarm.id,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }

    debugPrint('Alarm scheduled: ${alarm.label} at ${alarm.formattedTime}');
  }

  Future<void> cancelAlarm(String alarmId) async {
    try {
      final id = int.parse(alarmId);
      await _notifications.cancel(id);

      // Cancel all repeat day variations
      for (int day = 0; day < 7; day++) {
        await _notifications.cancel(id + day);
      }

      debugPrint('Alarm cancelled: $alarmId');
    } catch (e) {
      debugPrint('Error cancelling alarm: $e');
    }
  }

  Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
    debugPrint('All alarms cancelled');
  }

  Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Play alarm sound
  Future<void> _playAlarmSound() async {
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.play(AssetSource('sounds/alarm.mp3'));
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer.setVolume(1.0);
      debugPrint('Alarm sound playing');
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  // Stop alarm sound
  Future<void> stopAlarmSound() async {
    try {
      await _alarmPlayer.stop();
      debugPrint('Alarm sound stopped');
    } catch (e) {
      debugPrint('Error stopping alarm sound: $e');
    }
  }

  void dispose() {
    _alarmPlayer.dispose();
  }
}
