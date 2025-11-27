import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

class AlarmProvider with ChangeNotifier {
  List<AlarmModel> _alarms = [];

  List<AlarmModel> get alarms => _alarms;

  AlarmProvider() {
    _loadSampleAlarms();
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
  }

  void addAlarm(AlarmModel alarm) {
    _alarms.add(alarm);
    notifyListeners();
  }

  void updateAlarm(String id, AlarmModel updatedAlarm) {
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
      notifyListeners();
    }
  }

  void toggleAlarm(String id) {
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index != -1) {
      _alarms[index].isEnabled = !_alarms[index].isEnabled;
      notifyListeners();
    }
  }

  void deleteAlarm(String id) {
    _alarms.removeWhere((alarm) => alarm.id == id);
    notifyListeners();
  }

  List<AlarmModel> get enabledAlarms =>
      _alarms.where((alarm) => alarm.isEnabled).toList();

  int get alarmCount => _alarms.length;
}
