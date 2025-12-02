import 'package:flutter/material.dart';

class CalendarProvider with ChangeNotifier {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, double> _sleepData = {};

  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  Map<DateTime, double> get sleepData => _sleepData;

  CalendarProvider() {
    _loadSampleData();
  }

  void _loadSampleData() {
    // Generate sample sleep data for the past 30 days
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      _sleepData[normalizedDate] = 6.0 + (i % 3) + (i % 2) * 0.5;
    }
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  void setSelectedDay(DateTime? day) {
    _selectedDay = day;
    notifyListeners();
  }

  double? getSleepHours(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _sleepData[normalizedDate];
  }

  void updateSleepHours(DateTime date, double hours) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _sleepData[normalizedDate] = hours;
    notifyListeners();
  }

  // Monthly statistics
  Map<String, double> getMonthlyStats(DateTime month) {
    final sleepHours = <double>[];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final hours = getSleepHours(date);
      if (hours != null) {
        sleepHours.add(hours);
      }
    }

    if (sleepHours.isEmpty) {
      return {'average': 0.0, 'max': 0.0, 'min': 0.0};
    }

    final sum = sleepHours.reduce((a, b) => a + b);
    final average = sum / sleepHours.length;
    final max = sleepHours.reduce((a, b) => a > b ? a : b);
    final min = sleepHours.reduce((a, b) => a < b ? a : b);

    return {
      'average': double.parse(average.toStringAsFixed(1)),
      'max': max,
      'min': min,
    };
  }

  Color getSleepQualityColor(double? hours) {
    if (hours == null) return Colors.grey.shade200;
    if (hours >= 8) return Colors.green.shade400;
    if (hours >= 7) return Colors.lightGreen.shade400;
    if (hours >= 6) return Colors.orange.shade400;
    return Colors.red.shade400;
  }
}
