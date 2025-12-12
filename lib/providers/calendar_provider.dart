import 'package:flutter/material.dart';
import '../models/sleep_entry.dart';

class CalendarProvider with ChangeNotifier {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, double> _dummyData = {}; // 11월 더미 데이터

  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  Map<DateTime, double> get dummyData => _dummyData;

  CalendarProvider() {
    _loadDummyDataForNovember();
  }

  void _loadDummyDataForNovember() {
    final now = DateTime.now();
    for (int day = 1; day <= 30; day++) {
      final date = DateTime(now.year, 11, day);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      _dummyData[normalizedDate] = 6.0 + (day % 4) + (day % 3) * 0.3;
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

  double? getSleepHours(DateTime date, List<SleepEntry>? actualEntries) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    if (date.month == 11) {
      return _dummyData[normalizedDate];
    }
    
    // 12월이면 실제 데이터에서 찾기
    if (date.month == 12 && actualEntries != null) {
      // 해당 날짜의 수면 기록 찾기 (기상 시간 기준으로 날짜 매칭)
      double totalHours = 0.0;
      int count = 0;
      
      for (final entry in actualEntries) {
        final entryDate = DateTime(entry.wakeTime.year, entry.wakeTime.month, entry.wakeTime.day);
        if (entryDate == normalizedDate) {
          totalHours += entry.duration.inMinutes / 60.0;
          count++;
        }
      }
      
      // 같은 날 여러 수면 기록이 있을 수 있으므로 합산
      return count > 0 ? totalHours : null;
    }
    
    // 다른 월이면 null 반환
    return null;
  }

  void updateSleepHours(DateTime date, double hours) {
    // 11월 더미 데이터만 업데이트 가능
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (date.month == 11) {
      _dummyData[normalizedDate] = hours;
      notifyListeners();
    }
    // 12월 데이터는 SleepProvider에서 관리하므로 여기서는 업데이트하지 않음
  }

  // Monthly statistics
  Map<String, double> getMonthlyStats(DateTime month, List<SleepEntry>? actualEntries) {
    final sleepHours = <double>[];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final hours = getSleepHours(date, actualEntries);
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
