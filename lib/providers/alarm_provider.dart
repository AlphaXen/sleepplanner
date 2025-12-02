import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/alarm_model.dart';
import '../services/alarm_notification_service.dart';

class AlarmProvider with ChangeNotifier {
  List<AlarmModel> _alarms = [];
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AlarmNotificationService _notificationService =
      AlarmNotificationService();
  Timer? _alarmCheckTimer;
  final Set<String> _triggeredToday = {};

  List<AlarmModel> get alarms => _alarms;

  AlarmProvider() {
    _initializeAlarms();
  }

  Future<void> _initializeAlarms() async {
    await _notificationService.initialize();

    // Set up callback for when alarm triggers
    _notificationService.onAlarmTriggered = (alarmId) {
      final alarm = _alarms.firstWhere(
        (a) => a.id == alarmId,
        orElse: () => _alarms.first,
      );
      playAlarmSound(alarm.soundPath);
    };

    _loadSampleAlarms();
    _startAlarmChecker();
  }

  void _startAlarmChecker() {
    // Check every 30 seconds for alarms
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForAlarms();
    });
    // Check immediately
    _checkForAlarms();
  }

  void _checkForAlarms() {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    final currentWeekday = now.weekday % 7; // 0=Sunday format

    for (final alarm in _alarms) {
      if (!alarm.isEnabled) continue;

      // Check if alarm time matches (within same minute)
      if (alarm.time.hour == currentTime.hour &&
          alarm.time.minute == currentTime.minute) {
        // Create unique key for today
        final todayKey = '${alarm.id}_${now.year}_${now.month}_${now.day}';
        if (_triggeredToday.contains(todayKey)) continue;

        // Check repeat days
        if (alarm.repeatDays.isEmpty ||
            alarm.repeatDays.contains(currentWeekday)) {
          debugPrint(
              '🔔 ALARM RINGING: ${alarm.label} at ${alarm.formattedTime}');
          playAlarmSound(alarm.soundPath);
          _triggeredToday.add(todayKey);

          // Auto-stop after 5 minutes
          Future.delayed(const Duration(minutes: 5), () {
            stopAlarmSound();
          });
        }
      }
    }

    // Clear triggered list at midnight
    if (now.hour == 0 && now.minute < 1) {
      _triggeredToday.clear();
    }
  }

  void _loadSampleAlarms() {
    // Sample alarms for demonstration
    _alarms = [
      AlarmModel(
        id: '1',
        time: const TimeOfDay(hour: 7, minute: 0),
        label: 'Wake up',
        isEnabled: true,
        repeatDays: [1, 2, 3, 4, 5], // Weekdays
      ),
      AlarmModel(
        id: '2',
        time: const TimeOfDay(hour: 22, minute: 30),
        label: 'Bedtime',
        isEnabled: true,
        repeatDays: [0, 1, 2, 3, 4, 5, 6], // Every day
      ),
    ];

    // Schedule all enabled alarms
    for (final alarm in _alarms) {
      if (alarm.isEnabled) {
        _notificationService.scheduleAlarm(alarm);
      }
    }
  }

  void addAlarm(AlarmModel alarm) {
    _alarms.add(alarm);
    if (alarm.isEnabled) {
      _notificationService.scheduleAlarm(alarm);
    }
    notifyListeners();
  }

  void updateAlarm(String id, AlarmModel updatedAlarm) {
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
      _notificationService.cancelAlarm(id);
      if (updatedAlarm.isEnabled) {
        _notificationService.scheduleAlarm(updatedAlarm);
      }
      notifyListeners();
    }
  }

  void toggleAlarm(String id) {
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index != -1) {
      _alarms[index].isEnabled = !_alarms[index].isEnabled;
      if (_alarms[index].isEnabled) {
        _notificationService.scheduleAlarm(_alarms[index]);
      } else {
        _notificationService.cancelAlarm(id);
      }
      notifyListeners();
    }
  }

  void deleteAlarm(String id) {
    _notificationService.cancelAlarm(id);
    _alarms.removeWhere((alarm) => alarm.id == id);
    notifyListeners();
  }

  List<AlarmModel> get enabledAlarms =>
      _alarms.where((alarm) => alarm.isEnabled).toList();

  int get alarmCount => _alarms.length;

  // Play alarm sound
  Future<void> playAlarmSound(String soundPath) async {
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.play(AssetSource(soundPath));
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  // Stop alarm sound
  Future<void> stopAlarmSound() async {
    try {
      await _alarmPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping alarm sound: $e');
    }
  }

  @override
  void dispose() {
    _alarmCheckTimer?.cancel();
    _alarmPlayer.dispose();
    super.dispose();
  }
}
