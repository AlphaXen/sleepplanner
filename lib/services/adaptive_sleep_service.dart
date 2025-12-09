import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/adaptive_params.dart';
import '../models/shift_info.dart';
import '../models/daily_plan.dart';
import '../models/weekly_schedule.dart';
import '../utils/date_utils.dart';

class AdaptiveSleepService {
  /// 하루 단위 추천 (Daily Recommendation)
  /// 주간 스케줄이 있으면 오늘의 근무 일정을 사용하고, 근무 시간대에는 수면 권장을 하지 않음
  DailyPlan? computeDailyPlan({
    required AdaptiveParams params,
    ShiftInfo? shift,
    WeeklySchedule? weeklySchedule,
    int dayStartHour = 0,
  }) {
    final now = DateTime.now();
    debugPrint('📋 AdaptiveSleepService.computeDailyPlan 시작');
    debugPrint('   현재 시간: ${now.toString()}');
    
    // 주간 스케줄이 있으면 오늘의 근무 일정 가져오기
    if (weeklySchedule != null) {
      final todayKey = getTodayKey(dayStartHour);
      shift = weeklySchedule.getShiftForDate(todayKey);
      debugPrint('   주간 스케줄에서 오늘 근무 일정 조회: ${shift?.type ?? "없음"}');
    }
    
    // 근무 일정이 없으면 null 반환 (수면 권장 없음)
    if (shift == null) {
      debugPrint('   ⚠️ 근무 일정이 없어 수면 권장을 생성하지 않습니다.');
      return null;
    }
    
    debugPrint('   근무 유형: ${shift.type}');
    debugPrint('   근무 시작 (원본): ${shift.shiftStart?.toString() ?? "null"}');
    debugPrint('   근무 종료 (원본): ${shift.shiftEnd?.toString() ?? "null"}');
    debugPrint('   선호 수면 중간: ${shift.preferredMid?.toString() ?? "null"}');
    
    // 근무 시간대에 수면 권장하지 않음
    if (shift.shiftStart != null && shift.shiftEnd != null) {
      final workStart = shift.shiftStart!;
      final workEnd = shift.shiftEnd!;
      
      // 오늘 날짜 기준으로 근무 시간 계산
      final today = DateTime(now.year, now.month, now.day);
      DateTime todayWorkStart = DateTime(today.year, today.month, today.day, workStart.hour, workStart.minute);
      DateTime todayWorkEnd = DateTime(today.year, today.month, today.day, workEnd.hour, workEnd.minute);
      
      // 야간 근무의 경우 시작 시간이 종료 시간보다 나중일 수 있음 (예: 22시-6시)
      if (todayWorkStart.isAfter(todayWorkEnd)) {
        // 전날 밤부터 오늘 아침까지인 경우
        if (now.hour < todayWorkEnd.hour) {
          // 오늘 아침 근무 종료 시간이 아직 안 지났다면
          todayWorkStart = todayWorkStart.subtract(const Duration(days: 1));
        } else {
          // 오늘 밤부터 내일 아침까지인 경우
          todayWorkEnd = todayWorkEnd.add(const Duration(days: 1));
        }
      }
      
      // 현재 시간이 근무 시간대인지 확인
      if (now.isAfter(todayWorkStart) && now.isBefore(todayWorkEnd)) {
        debugPrint('   ⚠️ 현재 근무 시간대입니다. 수면 권장을 하지 않습니다.');
        debugPrint('      근무 시간: ${todayWorkStart.toString()} ~ ${todayWorkEnd.toString()}');
        return null;
      }
    }
    
    final tSleepHours = params.tSleep;
    final tSleep = Duration(
      hours: tSleepHours.floor(),
      minutes: ((tSleepHours % 1) * 60).round(),
    );

    late DateTime startSleep;
    late DateTime endSleep;

    // STEP 2. 메인 수면 시간 계산
    switch (shift.type) {
      case ShiftType.night:
        {
          // 야간 근무: 근무 종료 후 수면
          // 야간 근무는 전날 밤 시작 → 오늘 아침 종료 패턴 (예: 22:00-06:00)
          // "오늘의 적응형 수면 추천"은 다음 야간 근무를 위한 수면 시간
          final end = shift.shiftEnd!;
          final today = DateTime(now.year, now.month, now.day);
          
          const bufferHours = 1.5;
          final buffer = Duration(
            hours: bufferHours.floor(),
            minutes: ((bufferHours % 1) * 60).round(),
          );
          final chrono = Duration(
            hours: params.chronoOffset.floor(),
            minutes: ((params.chronoOffset % 1) * 60).round(),
          );
          
          debugPrint('   🏙️ 야간 근무 계산:');
          debugPrint('      근무 종료 (원본): ${end.toString()}');
          debugPrint('      현재 시간: ${now.toString()}');
          
          // 다음 야간 근무 종료 시간 계산
          // 오늘 날짜의 근무 종료 시간
          final todayEndTime = DateTime(today.year, today.month, today.day, end.hour, end.minute);
          
          // 오늘 근무 종료 후 수면 시작 시간
          final todaySleepStart = todayEndTime.add(buffer).add(chrono);
          
          debugPrint('      오늘 근무 종료: ${todayEndTime.toString()}');
          debugPrint('      오늘 수면 시작 예상: ${todaySleepStart.toString()}');
          
          // 현재 시간에 따라 적절한 수면 시간 선택
          DateTime endDate;
          
          if (todaySleepStart.isBefore(now)) {
            // 오늘 수면 시간이 이미 지났다면 → 내일 근무 기준으로 계산
            // (다음 야간 근무는 내일 밤 ~ 모레 아침)
            endDate = todayEndTime.add(const Duration(days: 1));
            debugPrint('      → 오늘 수면 시간 지남: 내일 근무 종료 기준 (${endDate.toString()})');
          } else {
            // 아직 오늘 수면 시간이 남아있다면 → 오늘 근무 종료 기준
            endDate = todayEndTime;
            debugPrint('      → 오늘 수면 시간 남아있음: 오늘 근무 종료 기준 (${endDate.toString()})');
          }
          
          startSleep = endDate.add(buffer).add(chrono);
          endSleep = startSleep.add(tSleep);
          
          // 수면 시작이 여전히 과거면 하루 더 추가
          if (startSleep.isBefore(now)) {
            debugPrint('      ⚠️ 계산된 수면이 여전히 과거 - 하루 추가');
            endDate = endDate.add(const Duration(days: 1));
            startSleep = endDate.add(buffer).add(chrono);
            endSleep = startSleep.add(tSleep);
          }
          
          debugPrint('      최종 수면: ${startSleep.toString()} ~ ${endSleep.toString()}');
          break;
        }
      case ShiftType.day:
        {
          // 주간 근무: 근무 시작 전 수면
          final start = shift.shiftStart!;
          
          // 오늘 날짜로 맞춰주기
          final today = DateTime(now.year, now.month, now.day);
          final startDate = DateTime(today.year, today.month, today.day, start.hour, start.minute);
          
          // 근무 시작 시간이 현재보다 이전이면 내일로
          final adjustedStart = startDate.isBefore(now)
              ? startDate.add(const Duration(days: 1))
              : startDate;
          
          const beforeWork = Duration(hours: 1);
          endSleep = adjustedStart.subtract(beforeWork);
          
          final chrono = Duration(
            hours: params.chronoOffset.floor(),
            minutes: ((params.chronoOffset % 1) * 60).round(),
          );
          // chronoOffset: 양수면 늦게 자는 성향(늦게 자고 늦게 일어남)
          // 주간 근무에서는 일찍 일어나야 하므로, chronoOffset이 양수면 더 일찍 자야 함
          // 따라서 subtract로 처리 (예: chronoOffset이 +2h면 2시간 더 일찍 자야 함)
          startSleep = endSleep.subtract(tSleep).subtract(chrono);
          
          debugPrint('   ☀️ 주간 근무 계산:');
          debugPrint('      근무 시작: ${start.toString()}');
          debugPrint('      조정된 시작: ${adjustedStart.toString()}');
          debugPrint('      기상 시간: ${endSleep.toString()}');
          debugPrint('      수면 시작: ${startSleep.toString()}');
          debugPrint('      최종 수면: ${startSleep.toString()} ~ ${endSleep.toString()}');
          
          // 만약 수면 시작이 과거면 하루 전으로
          if (startSleep.isBefore(now)) {
            debugPrint('      ⚠️ 수면 시작이 과거 - 하루 추가');
            startSleep = startSleep.add(const Duration(days: 1));
            endSleep = endSleep.add(const Duration(days: 1));
            debugPrint('      → 재조정된 수면: ${startSleep.toString()} ~ ${endSleep.toString()}');
          }
          break;
        }
      case ShiftType.off:
        {
          // 휴무일: preferredMid 기준으로 수면
          final mid = shift.preferredMid ?? DateTime.now().add(const Duration(hours: 3));
          
          // 오늘 날짜로 맞춰주기
          final today = DateTime(now.year, now.month, now.day);
          final midDate = DateTime(today.year, today.month, today.day, mid.hour, mid.minute);
          
          // preferredMid가 과거면 내일로
          final adjustedMid = midDate.isBefore(now)
              ? midDate.add(const Duration(days: 1))
              : midDate;
          
          startSleep = adjustedMid.subtract(tSleep ~/ 2);
          endSleep = adjustedMid.add(tSleep ~/ 2);
          
          debugPrint('   🛌 휴무일 계산:');
          debugPrint('      선호 수면 중간: ${mid.toString()}');
          debugPrint('      조정된 중간: ${adjustedMid.toString()}');
          debugPrint('      최종 수면: ${startSleep.toString()} ~ ${endSleep.toString()}');
          break;
        }
    }
    
    debugPrint('   ✅ 최종 계산된 수면 시간:');
    debugPrint('      수면 시작: ${startSleep.toString()}');
    debugPrint('      수면 종료: ${endSleep.toString()}');

    // STEP 3. 카페인 컷오프 계산
    final effectiveWindowHours =
        params.cafWindow + (params.cafSens - 0.5) * 2.0;
    final effectiveWindow = Duration(
      hours: effectiveWindowHours.floor(),
      minutes: ((effectiveWindowHours % 1) * 60).round(),
    );
    final caffeineCutoff = startSleep.subtract(effectiveWindow);

    // STEP 4. 취침 준비 시작 시간
    final winddownStart =
        startSleep.subtract(Duration(minutes: params.winddownMinutes));

    // STEP 5. 빛 노출 전략
    final lightPlan = _buildLightPlan(
      shiftType: shift.type,
      lightSens: params.lightSens,
      startSleep: startSleep,
      endSleep: endSleep,
    );

    final notes = <String>[];
    notes.add('주요 수면: ${_formatTime(startSleep)} ~ ${_formatTime(endSleep)}');
    notes.add('카페인 컷오프: ${_formatTime(caffeineCutoff)} 이후 카페인 자제');
    notes.add('취침 준비 시작: ${_formatTime(winddownStart)} 부터 휴대폰/밝은 빛 줄이기');

    return DailyPlan(
      mainSleepStart: startSleep,
      mainSleepEnd: endSleep,
      caffeineCutoff: caffeineCutoff,
      winddownStart: winddownStart,
      lightPlan: lightPlan,
      notes: notes,
    );
  }

  Map<String, dynamic> _buildLightPlan({
    required ShiftType shiftType,
    required double lightSens,
    required DateTime startSleep,
    required DateTime endSleep,
  }) {
    switch (shiftType) {
      case ShiftType.night:
        return {
          'strategy': 'night_shift',
          'work_bright_light': true,
          'post_shift_block_light': true,
          'light_sensitivity': lightSens,
        };
      case ShiftType.day:
        return {
          'strategy': 'day_shift',
          'morning_bright_light': true,
          'evening_dim_light': true,
          'light_sensitivity': lightSens,
        };
      case ShiftType.off:
        return {
          'strategy': 'off_day',
          'align_with_preferred_mid': true,
          'light_sensitivity': lightSens,
        };
    }
  }

  // Weekly Adaptation 요약형 – 나중에 데이터 쌓이면 활용 가능
  AdaptiveParams adaptWeekly({
    required AdaptiveParams current,
    required double avgActualSleep,
    required double avgSleepScore,         // 1~5
    required double avgDaytimeSleepiness,  // 1~5
    required double meanScoreNoLateCaf,
    required double meanScoreLateCaf,
    required double meanScoreLowLight,
    required double meanScoreHighLight,
    required DateTime? preferredMidOffDays,
    required DateTime mid0, // 기준 mid (예: 새벽 3시)
    double eta = 0.2,
  }) {
    double tSleep = current.tSleep;
    double cafWindow = current.cafWindow;
    double cafSens = current.cafSens;
    double lightSens = current.lightSens;
    double chronoOffset = current.chronoOffset;

    // STEP 1: 손실값 (디버깅용)
    // final errSleep = (avgActualSleep - tSleep).abs();
    // final errScore = max(0, 5 - avgSleepScore);
    // final errSleepiness = max(0, avgDaytimeSleepiness - 2);
    // final L = 1.0 * errSleep + 1.0 * errSleepiness + 1.0 * errScore;
    // L 은 지금은 로그/분석용으로만 사용 가능

    // STEP 2: 목표 수면시간 조정
    final tSleepNew = _clamp(
      (1 - eta) * tSleep + eta * (avgActualSleep + 0.5),
      5.5,
      9.0,
    );

    // STEP 3: 카페인 민감도 업데이트
    final diffCaf = meanScoreNoLateCaf - meanScoreLateCaf;
    if (diffCaf > 0.5) {
      cafSens = _clamp(cafSens + 0.1, 0.0, 1.0);
      cafWindow = cafWindow + 0.5;
    } else if (diffCaf < 0.1) {
      cafSens = _clamp(cafSens - 0.1, 0.0, 1.0);
      cafWindow = max(0, cafWindow - 0.5);
    }

    // STEP 4: 빛 민감도 업데이트
    final diffLight = meanScoreLowLight - meanScoreHighLight;
    if (diffLight > 0.5) {
      lightSens = _clamp(lightSens + 0.1, 0.0, 1.0);
    } else if (diffLight < 0.1) {
      lightSens = _clamp(lightSens - 0.1, 0.0, 1.0);
    }

    // STEP 5: 크로노타입 업데이트
    if (preferredMidOffDays != null) {
      final diffMidHours =
          preferredMidOffDays.difference(mid0).inMinutes / 60.0;
      chronoOffset =
          (1 - eta) * chronoOffset + eta * diffMidHours;
    }

    return current.copyWith(
      tSleep: tSleepNew,
      cafWindow: cafWindow,
      cafSens: cafSens,
      lightSens: lightSens,
      chronoOffset: chronoOffset,
    );
  }

  double _clamp(double v, double minV, double maxV) {
    return v < minV ? minV : (v > maxV ? maxV : v);
  }

  String _formatTime(DateTime dt) {
    // DateTime은 이미 로컬 시간이므로 toLocal() 불필요
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}