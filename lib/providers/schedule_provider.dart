import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weekly_schedule.dart';
import '../models/shift_info.dart';
import '../models/sleep_entry.dart';
import '../utils/date_utils.dart';

class ScheduleProvider extends ChangeNotifier {
  WeeklySchedule? _currentSchedule;
  bool _isLoading = false;
  bool _isLoaded = false;

  WeeklySchedule? get currentSchedule => _currentSchedule;
  bool get isLoaded => _isLoaded;

  ScheduleProvider() {
    _loadSchedule();
  }
  
  Future<void> waitForLoad() async {
    if (_isLoaded) return;
    
    // 최대 2초까지 대기
    int attempts = 0;
    while (!_isLoaded && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  Future<void> _loadSchedule() async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('weekly_schedule');
      
      debugPrint('📅 주간 스케줄 로드 시도:');
      debugPrint('   저장된 데이터: ${raw != null ? "${raw.length} bytes" : "없음"}');
      
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _currentSchedule = WeeklySchedule.fromJson(json);
        notifyListeners();
        debugPrint('   ✅ 주간 스케줄 로드 완료');
        debugPrint('   weekStart: ${_currentSchedule?.weekStart.toString()}');
        debugPrint('   shifts 개수: ${_currentSchedule?.shifts.length ?? 0}');
        debugPrint('   패턴: ${_currentSchedule?.detectPattern() ?? "없음"}');
      } else {
        debugPrint('   ℹ️ 저장된 주간 스케줄 없음');
      }
      
      _isLoaded = true;
    } catch (e) {
      debugPrint('❌ 주간 스케줄 로드 오류: $e');
      _isLoaded = true; // 에러가 나도 로드 시도는 완료로 표시
    } finally {
      _isLoading = false;
    }
  }

  Future<void> saveSchedule(WeeklySchedule schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = schedule.toJson();
      final jsonString = jsonEncode(json);
      
      debugPrint('📅 주간 스케줄 저장 시작:');
      debugPrint('   weekStart: ${schedule.weekStart.toString()}');
      debugPrint('   shifts 개수: ${schedule.shifts.length}');
      debugPrint('   JSON 길이: ${jsonString.length} bytes');
      
      final saved = await prefs.setString('weekly_schedule', jsonString);
      
      if (!saved) {
        debugPrint('   ⚠️ SharedPreferences 저장 실패');
        throw Exception('주간 스케줄 저장 실패: SharedPreferences write failed');
      }
      
      // 저장 확인 - 저장 직후 다시 읽어서 확인
      final verifyString = prefs.getString('weekly_schedule');
      if (verifyString == null || verifyString.isEmpty) {
        debugPrint('   ⚠️ 저장 확인 실패: 데이터가 없음');
        throw Exception('주간 스케줄 저장 확인 실패: 저장된 데이터가 없음');
      }
      
      if (verifyString != jsonString) {
        debugPrint('   ⚠️ 저장 확인 실패: 데이터 불일치');
        debugPrint('   원본 길이: ${jsonString.length} bytes');
        debugPrint('   저장된 길이: ${verifyString.length} bytes');
        // JSON 파싱해서 내용 비교
        try {
          final savedJson = jsonDecode(verifyString) as Map<String, dynamic>;
          final originalJson = jsonDecode(jsonString) as Map<String, dynamic>;
          if (savedJson['weekStart'] != originalJson['weekStart'] ||
              (savedJson['shifts'] as Map).length != (originalJson['shifts'] as Map).length) {
            throw Exception('주간 스케줄 저장 확인 실패: 저장된 데이터 내용이 일치하지 않음');
          }
        } catch (e) {
          debugPrint('   ⚠️ 저장 확인 중 오류: $e');
          // 파싱 에러가 나도 저장은 성공했을 수 있으므로 계속 진행
        }
      }
      
      _currentSchedule = schedule;
      notifyListeners();
      debugPrint('   ✅ 주간 스케줄 저장 완료');
      debugPrint('   패턴: ${schedule.detectPattern()}');
      
      // 최종 확인: 다시 로드해서 검증
      try {
        final reloadedString = prefs.getString('weekly_schedule');
        if (reloadedString != null && reloadedString.isNotEmpty) {
          final reloadedJson = jsonDecode(reloadedString) as Map<String, dynamic>;
          final reloadedSchedule = WeeklySchedule.fromJson(reloadedJson);
          debugPrint('   ✅ 최종 검증: 저장된 스케줄을 다시 로드하여 확인');
          debugPrint('   재로드된 패턴: ${reloadedSchedule.detectPattern()}');
        }
      } catch (e) {
        debugPrint('   ⚠️ 최종 검증 중 오류 (무시): $e');
      }
    } catch (e) {
      debugPrint('❌ 주간 스케줄 저장 오류: $e');
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

  Future<void> generateScheduleFromSleepEntries(List<SleepEntry> entries, {int dayStartHour = 0, bool force = false}) async {
    if (entries.isEmpty) {
      debugPrint('No sleep entries to generate schedule');
      return;
    }
    
    if (!force && _currentSchedule != null) {
      debugPrint('기존 스케줄이 존재하여 자동 생성하지 않습니다.');
      return;
    }

    final todayKey = getTodayKey(dayStartHour);
    final monday = todayKey.subtract(Duration(days: todayKey.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);

    // 최근 7일의 수면 기록 분석
    final shifts = <int, ShiftInfo>{};
    
    // 각 날짜별로 수면 기록이 있는지 확인
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final targetDate = weekStart.add(Duration(days: dayIndex));
      
      // 해당 날짜에 기상한 수면 기록 찾기 (wakeTime 기준, 하루 시작 시간 고려)
      final entryForDay = entries.where((e) {
        final wakeDateKey = getDateKey(e.wakeTime, dayStartHour);
        return wakeDateKey.year == targetDate.year &&
               wakeDateKey.month == targetDate.month &&
               wakeDateKey.day == targetDate.day;
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
        // 수면 중간 시간을 새벽 3시로 설정 (정상적인 수면 시간대)
        final preferredMid = DateTime(targetDate.year, targetDate.month, targetDate.day, 3, 0);
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

  void updateScheduleFromEntries(List<SleepEntry> entries) {
    generateScheduleFromSleepEntries(entries);
  }
}

