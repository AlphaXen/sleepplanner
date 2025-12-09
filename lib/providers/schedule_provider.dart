import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weekly_schedule.dart';
import '../models/shift_info.dart';
import '../models/sleep_entry.dart';

class ScheduleProvider extends ChangeNotifier {
  WeeklySchedule? _currentSchedule;

  WeeklySchedule? get currentSchedule => _currentSchedule;

  ScheduleProvider() {
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('weekly_schedule');
      
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _currentSchedule = WeeklySchedule.fromJson(json);
        notifyListeners();
        debugPrint('Schedule loaded successfully');
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
  }

  Future<void> saveSchedule(WeeklySchedule schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = schedule.toJson();
      await prefs.setString('weekly_schedule', jsonEncode(json));
      
      _currentSchedule = schedule;
      notifyListeners();
      debugPrint('Schedule saved successfully');
    } catch (e) {
      debugPrint('Error saving schedule: $e');
      rethrow;
    }
  }

  Future<void> clearSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('weekly_schedule');
      
      _currentSchedule = null;
      notifyListeners();
      debugPrint('Schedule cleared successfully');
    } catch (e) {
      debugPrint('Error clearing schedule: $e');
    }
  }

  bool get hasSchedule => _currentSchedule != null;

  /// 수면 기록 데이터로부터 주간 스케줄 자동 생성
  Future<void> generateScheduleFromSleepEntries(List<SleepEntry> entries) async {
    if (entries.isEmpty) {
      debugPrint('No sleep entries to generate schedule');
      return;
    }

    // 현재 주의 월요일 구하기
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);

    // 최근 7일의 수면 기록 분석
    final shifts = <int, ShiftInfo>{};
    
    // 각 날짜별로 수면 기록이 있는지 확인
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final targetDate = weekStart.add(Duration(days: dayIndex));
      final dateKey = DateTime(targetDate.year, targetDate.month, targetDate.day);
      
      // 해당 날짜에 기상한 수면 기록 찾기 (wakeTime 기준)
      final entryForDay = entries.where((e) {
        final wakeDateKey = DateTime(e.wakeTime.year, e.wakeTime.month, e.wakeTime.day);
        return wakeDateKey == dateKey;
      }).toList();

      if (entryForDay.isNotEmpty) {
        // 가장 최근 기록 사용
        final entry = entryForDay.first;
        
        if (entry.isNightShift) {
          // 야간 근무: 수면 시간을 기반으로 근무 시간 추정
          // 일반적으로 야간 근무 후 22시-8시 사이에 수면
          final sleepHour = entry.sleepTime.hour;
          
          // 야간 근무 시간 추정 (수면 전 근무)
          DateTime shiftStart;
          DateTime shiftEnd;
          
          if (sleepHour >= 20 || sleepHour < 6) {
            // 20시 이후 또는 6시 이전에 수면 = 야간 근무 후
            // 근무 시간: 전날 22시 ~ 당일 6시
            final prevDay = targetDate.day > 0 ? targetDate.day - 1 : targetDate.day;
            shiftStart = DateTime(
              targetDate.year,
              targetDate.month,
              prevDay,
              22,
              0,
            );
            shiftEnd = DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
              6,
              0,
            );
          } else {
            // 기본 야간 근무 시간 (22시-6시)
            final prevDay = targetDate.day > 0 ? targetDate.day - 1 : targetDate.day;
            shiftStart = DateTime(targetDate.year, targetDate.month, prevDay, 22, 0);
            shiftEnd = DateTime(targetDate.year, targetDate.month, targetDate.day, 6, 0);
          }
          
          shifts[dayIndex] = ShiftInfo.night(shiftStart: shiftStart, shiftEnd: shiftEnd);
        } else {
          // 주간 근무: 수면 시간 패턴 분석
          final sleepHour = entry.sleepTime.hour;
          
          if (sleepHour >= 22 || sleepHour < 6) {
            // 밤에 수면 = 주간 근무 전날
            // 근무 시간 추정 (일반적으로 9시-17시)
            final shiftStart = DateTime(targetDate.year, targetDate.month, targetDate.day, 9, 0);
            final shiftEnd = DateTime(targetDate.year, targetDate.month, targetDate.day, 17, 0);
            shifts[dayIndex] = ShiftInfo.day(shiftStart: shiftStart, shiftEnd: shiftEnd);
          } else {
            // 낮에 수면 = 야간 근무 또는 특수한 경우
            // 기본적으로 주간 근무로 처리
            final shiftStart = DateTime(targetDate.year, targetDate.month, targetDate.day, 9, 0);
            final shiftEnd = DateTime(targetDate.year, targetDate.month, targetDate.day, 17, 0);
            shifts[dayIndex] = ShiftInfo.day(shiftStart: shiftStart, shiftEnd: shiftEnd);
          }
        }
      } else {
        // 기록이 없는 날은 휴무로 처리 (또는 이전 패턴 기반)
        // 수면 중간 시간을 해당 날 정오로 설정
        final preferredMid = DateTime(targetDate.year, targetDate.month, targetDate.day, 12, 0);
        shifts[dayIndex] = ShiftInfo.off(preferredMid: preferredMid);
      }
    }

    // 주간 스케줄 생성 및 저장
    if (shifts.isNotEmpty) {
      final schedule = WeeklySchedule(
        weekStart: weekStart,
        shifts: shifts,
      );
      
      await saveSchedule(schedule);
      debugPrint('Schedule generated from sleep entries: ${schedule.detectPattern()}');
    }
  }

  /// 수면 기록 변경 시 스케줄 자동 업데이트
  void updateScheduleFromEntries(List<SleepEntry> entries) {
    generateScheduleFromSleepEntries(entries);
  }
}

