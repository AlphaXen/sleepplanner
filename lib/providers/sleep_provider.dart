import 'package:flutter/material.dart';
import '../models/sleep_entry.dart';

class SleepProvider extends ChangeNotifier {
  final List<SleepEntry> _entries = [];
  int _dailyTargetHours = 7;
  bool _isNightShiftWorker = true;

  List<SleepEntry> get entries => List.unmodifiable(_entries);
  int get dailyTargetHours => _dailyTargetHours;
  bool get isNightShiftWorker => _isNightShiftWorker;

  void setDailyTarget(int hours) {
    _dailyTargetHours = hours;
    notifyListeners();
  }

  void setNightShiftWorker(bool value) {
    _isNightShiftWorker = value;
    notifyListeners();
  }

  void addEntry(SleepEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }

  Duration get todaySleepDuration {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Duration total = Duration.zero;

    for (final e in _entries) {
      final day = DateTime(e.sleepTime.year, e.sleepTime.month, e.sleepTime.day);
      if (day == today) {
        total += e.duration;
      }
    }
    return total;
  }

  double get todayProgress {
    final targetMinutes = _dailyTargetHours * 60;
    final sleptMinutes = todaySleepDuration.inMinutes;
    if (targetMinutes == 0) return 0;
    return (sleptMinutes / targetMinutes).clamp(0, 1);
  }
}
