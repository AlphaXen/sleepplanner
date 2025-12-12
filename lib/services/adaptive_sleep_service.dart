import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/adaptive_params.dart';
import '../models/shift_info.dart';
import '../models/daily_plan.dart';
import '../models/weekly_schedule.dart';
import '../utils/date_utils.dart';

class AdaptiveSleepService {
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
      
      debugPrint('   근무 시간 계산:');
      debugPrint('      원본 시작: ${workStart.toString()}');
      debugPrint('      원본 종료: ${workEnd.toString()}');
      
      // ShiftInfo에 저장된 날짜 정보를 그대로 사용
      // 주간 스케줄에서 가져온 shift의 날짜는 해당 요일의 날짜 정보를 포함
      DateTime actualWorkStart = workStart;
      DateTime actualWorkEnd = workEnd;
      
      // 종료 시간이 시작 시간보다 이전이면 다음날로 해석
      if (actualWorkEnd.isBefore(actualWorkStart) || actualWorkEnd == actualWorkStart) {
        // 같은 날짜인데 시간만 역순이거나 같으면, 종료 시간을 다음날로
        actualWorkEnd = actualWorkEnd.add(const Duration(days: 1));
      }
      
      // 현재 시간이 실제 근무 시간대와 겹치는지 확인
      // 날짜를 고려하여 정확하게 비교
      final isDuringWork = (now.isAfter(actualWorkStart) || now.isAtSameMomentAs(actualWorkStart)) 
          && now.isBefore(actualWorkEnd);
      
      debugPrint('      실제 근무 시간: ${actualWorkStart.toString()} ~ ${actualWorkEnd.toString()}');
      debugPrint('      현재 시간: ${now.toString()}');
      debugPrint('      근무 중인가? $isDuringWork');
      
      if (isDuringWork) {
        debugPrint('   ⚠️ 현재 근무 시간대입니다. 수면 권장을 하지 않습니다.');
        return null;
      }
      
      // 주간 스케줄이 있으면 다른 날짜의 근무 시간대와 겹치는지 확인
      if (weeklySchedule != null) {
        // 계산된 수면 시간이 나중에 확인되므로, 여기서는 주간 스케줄 정보만 저장
        debugPrint('   주간 스케줄 확인: ${weeklySchedule.weekStart.toString()}');
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
          final workStart = shift.shiftStart!;
          final workEnd = shift.shiftEnd!;
          
          debugPrint('   🏙️ 야간 근무 계산:');
          debugPrint('      근무 시작 (원본): ${workStart.toString()}');
          debugPrint('      근무 종료 (원본): ${workEnd.toString()}');
          debugPrint('      현재 시간: ${now.toString()}');
          
          // 실제 근무 시간 계산 (날짜 정보 포함)
          DateTime actualWorkStart = workStart;
          DateTime actualWorkEnd = workEnd;
          
          // 종료 시간이 시작 시간보다 이전이면 다음날로 해석
          if (actualWorkEnd.isBefore(actualWorkStart) || actualWorkEnd == actualWorkStart) {
            actualWorkEnd = actualWorkEnd.add(const Duration(days: 1));
          }
          
          debugPrint('      실제 근무 시간: ${actualWorkStart.toString()} ~ ${actualWorkEnd.toString()}');
          
          // 현재 시간이 근무 시작 전인지, 근무 중인지, 근무 후인지 판단
          final isBeforeWork = now.isBefore(actualWorkStart);
          final isDuringWork = (now.isAfter(actualWorkStart) || now.isAtSameMomentAs(actualWorkStart)) 
              && now.isBefore(actualWorkEnd);
          final isAfterWork = now.isAfter(actualWorkEnd) || now.isAtSameMomentAs(actualWorkEnd);
          
          debugPrint('      근무 시작 전? $isBeforeWork');
          debugPrint('      근무 중? $isDuringWork');
          debugPrint('      근무 후? $isAfterWork');
          
          const bufferHours = 1.5;
          final buffer = Duration(
            hours: bufferHours.floor(),
            minutes: ((bufferHours % 1) * 60).round(),
          );
          final chrono = Duration(
            hours: params.chronoOffset.floor(),
            minutes: ((params.chronoOffset % 1) * 60).round(),
          );
          
          DateTime targetWorkEnd;
          
          if (isBeforeWork) {
            // 근무 시작 전: 오늘 근무 종료 후 수면
            targetWorkEnd = actualWorkEnd;
            debugPrint('      → 근무 시작 전: 오늘 근무 종료 후 수면');
          } else if (isDuringWork) {
            // 근무 중: 이미 체크되어 null 반환됨 (여기 도달하지 않음)
            targetWorkEnd = actualWorkEnd;
            debugPrint('      → 근무 중: 근무 종료 후 수면');
          } else {
            // 근무 후: 이미 근무가 끝났으므로 다음 근무 종료 후 수면
            // 다음 근무는 내일 같은 시간대
            targetWorkEnd = actualWorkEnd.add(const Duration(days: 1));
            debugPrint('      → 근무 후: 다음 근무 종료 후 수면');
          }
          
          // 근무 종료 후 수면 시작
          startSleep = targetWorkEnd.add(buffer).add(chrono);
          endSleep = startSleep.add(tSleep);
          
          // 수면 시작이 현재 시간보다 과거면 하루 더 추가
          if (startSleep.isBefore(now)) {
            debugPrint('      ⚠️ 계산된 수면이 과거 - 하루 추가');
            targetWorkEnd = targetWorkEnd.add(const Duration(days: 1));
            startSleep = targetWorkEnd.add(buffer).add(chrono);
            endSleep = startSleep.add(tSleep);
          }
          
          debugPrint('      목표 근무 종료 시간: ${targetWorkEnd.toString()}');
          debugPrint('      최종 수면: ${startSleep.toString()} ~ ${endSleep.toString()}');
          break;
        }
      case ShiftType.day:
        {
          // 주간 근무: 근무 시작 전 수면
          // 주간 근무는 항상 전날 밤에 자고, 근무 시작 전에 일어나야 함
          final start = shift.shiftStart!;
          
          // 오늘 날짜로 맞춰주기
          final today = DateTime(now.year, now.month, now.day);
          final startDate = DateTime(today.year, today.month, today.day, start.hour, start.minute);
          
          // 다음 근무 시작 시간 계산 (오늘 또는 내일)
          DateTime nextWorkStart;
          if (startDate.isBefore(now)) {
            // 오늘 근무 시작 시간이 이미 지났다면 → 내일 근무
            nextWorkStart = startDate.add(const Duration(days: 1));
            debugPrint('   ☀️ 주간 근무 계산: 오늘 근무 시간 지남 → 내일 근무 기준');
          } else {
            // 오늘 근무 시작 시간이 남아있다면 → 오늘 근무
            nextWorkStart = startDate;
            debugPrint('   ☀️ 주간 근무 계산: 오늘 근무 기준');
          }
          
          // 기상 시간: 근무 시작 1시간 전
          const beforeWork = Duration(hours: 1);
          final targetWakeTime = nextWorkStart.subtract(beforeWork);
          
          // 크로노타입 오프셋
          final chrono = Duration(
            hours: params.chronoOffset.floor(),
            minutes: ((params.chronoOffset % 1) * 60).round(),
          );
          
          // 수면 시작 시간: 기상 시간에서 목표 수면 시간과 크로노타입 오프셋을 뺀 값
          // 주간 근무에서는 늦게 자는 성향(chronoOffset 양수)이 있으면 더 일찍 자야 함
          startSleep = targetWakeTime.subtract(tSleep).subtract(chrono);
          endSleep = targetWakeTime;
          
          // 주간 근무의 수면은 항상 밤 시간대(저녁~새벽)에 시작해야 함
          // 만약 수면 시작이 낮 시간대(6시~18시)라면 전날 밤으로 조정
          if (startSleep.hour >= 6 && startSleep.hour < 18) {
            // 낮 시간대면 전날 밤으로 조정
            // 수면 시작을 전날 저녁 22시로 설정
            final sleepStartDate = startSleep.subtract(const Duration(days: 1));
            startSleep = DateTime(
              sleepStartDate.year,
              sleepStartDate.month,
              sleepStartDate.day,
              22, // 저녁 10시
              0,
            );
            endSleep = startSleep.add(tSleep);
            
            // 기상 시간이 근무 시작 시간을 넘어서면 조정
            if (endSleep.isAfter(targetWakeTime)) {
              // 목표 기상 시간에 맞춰 수면 시작 시간 앞당기기
              startSleep = targetWakeTime.subtract(tSleep);
              endSleep = targetWakeTime;
            }
            
            debugPrint('      ⚠️ 수면 시간이 낮 시간대로 계산됨 → 전날 밤으로 조정');
          } else if (startSleep.isBefore(now)) {
            // 수면 시작이 현재 시간보다 과거면 오늘 밤으로 조정
            final todayEvening = DateTime(today.year, today.month, today.day, 22, 0);
            
            // 오늘 밤 22시에 자면 기상 시간이 언제인지 계산
            final candidateWakeTime = todayEvening.add(tSleep);
            
            // 기상 시간이 목표 기상 시간보다 늦으면 전날 밤으로 조정
            if (candidateWakeTime.isAfter(targetWakeTime)) {
              // 전날 밤에 자야 함
              final yesterday = today.subtract(const Duration(days: 1));
              startSleep = DateTime(yesterday.year, yesterday.month, yesterday.day, 22, 0);
              endSleep = startSleep.add(tSleep);
              
              // 여전히 목표 기상 시간을 넘으면 수면 시간 조정
              if (endSleep.isAfter(targetWakeTime)) {
                startSleep = targetWakeTime.subtract(tSleep);
                endSleep = targetWakeTime;
              }
            } else {
              // 오늘 밤에 자도 됨
              startSleep = todayEvening;
              endSleep = candidateWakeTime;
            }
            
            debugPrint('      ⚠️ 수면 시작이 과거 → 적절한 밤 시간대로 조정');
          }
          
          debugPrint('   ☀️ 주간 근무 계산:');
          debugPrint('      근무 시작 (원본): ${start.toString()}');
          debugPrint('      다음 근무 시작: ${nextWorkStart.toString()}');
          debugPrint('      목표 기상 시간: ${targetWakeTime.toString()}');
          debugPrint('      수면 시작: ${startSleep.toString()}');
          debugPrint('      기상 시간: ${endSleep.toString()}');
          debugPrint('      최종 수면: ${startSleep.toString()} ~ ${endSleep.toString()}');
          break;
        }
      case ShiftType.off:
        {
          // 휴무일: preferredMid 기준으로 수면
          // preferredMid는 새벽 시간대(0시~6시)여야 함
          DateTime? mid = shift.preferredMid;
          
          // preferredMid가 없거나 비정상적인 시간대(낮 시간대)면 기본값(새벽 3시) 사용
          if (mid == null || (mid.hour >= 6 && mid.hour < 22)) {
            debugPrint('   ⚠️ preferredMid가 비정상적이거나 없음 - 기본값(새벽 3시) 사용');
            mid = DateTime(now.year, now.month, now.day, 3, 0);
          }
          
          // 오늘 날짜로 맞춰주기
          final today = DateTime(now.year, now.month, now.day);
          
          // preferredMid 시간대가 새벽(0~6시)이면 오늘 새벽, 그 외면 내일 새벽
          DateTime adjustedMid;
          if (mid.hour >= 0 && mid.hour < 6) {
            // 새벽 시간대: 오늘 새벽으로 설정
            adjustedMid = DateTime(today.year, today.month, today.day, mid.hour, mid.minute);
            // 이미 지난 시간이면 내일 새벽으로
            if (adjustedMid.isBefore(now)) {
              adjustedMid = adjustedMid.add(const Duration(days: 1));
            }
          } else {
            // 저녁 시간대(22시~23시): 오늘 밤~내일 새벽으로 해석
            adjustedMid = DateTime(today.year, today.month, today.day, mid.hour, mid.minute);
            // 이미 지난 시간이면 내일로
            if (adjustedMid.isBefore(now)) {
              adjustedMid = adjustedMid.add(const Duration(days: 1));
            }
            // 저녁 시간대면 다음날 새벽 3시로 변환 (저녁 22시 → 다음날 새벽 3시)
            if (adjustedMid.hour >= 22 || adjustedMid.hour < 6) {
              adjustedMid = DateTime(adjustedMid.year, adjustedMid.month, adjustedMid.day, 3, 0);
              if (adjustedMid.isBefore(now)) {
                adjustedMid = adjustedMid.add(const Duration(days: 1));
              }
            }
          }
          
          // 수면 시작/종료 시간 계산 (mid-sleep 기준으로 반으로 나눔)
          startSleep = adjustedMid.subtract(tSleep ~/ 2);
          endSleep = adjustedMid.add(tSleep ~/ 2);
          
          // 수면 시작이 저녁(18시 이전)이면 전날 밤으로 조정
          if (startSleep.hour < 18) {
            // 전날 밤 22시부터 시작하도록 조정
            final sleepStartDate = startSleep.subtract(const Duration(days: 1));
            startSleep = DateTime(
              sleepStartDate.year,
              sleepStartDate.month,
              sleepStartDate.day,
              22, // 저녁 10시
              0,
            );
            endSleep = startSleep.add(tSleep);
            
            // mid-sleep 시간을 조정된 시간에 맞춤
            adjustedMid = startSleep.add(tSleep ~/ 2);
            
            debugPrint('      ⚠️ 수면 시작 시간 조정: 저녁 시간대로 변경');
          }
          
          // 수면 시작이 현재 시간보다 과거면 오늘 밤으로 조정
          if (startSleep.isBefore(now)) {
            final todayEvening = DateTime(today.year, today.month, today.day, 22, 0);
            startSleep = todayEvening;
            endSleep = startSleep.add(tSleep);
            adjustedMid = startSleep.add(tSleep ~/ 2);
            
            debugPrint('      ⚠️ 수면 시작이 과거 → 오늘 밤으로 조정');
          }
          
          debugPrint('   🛌 휴무일 계산:');
          debugPrint('      원본 선호 수면 중간: ${shift.preferredMid?.toString() ?? "null"}');
          debugPrint('      조정된 중간: ${adjustedMid.toString()}');
          debugPrint('      최종 수면: ${startSleep.toString()} ~ ${endSleep.toString()}');
          break;
        }
    }
    
    debugPrint('   ✅ 최종 계산된 수면 시간:');
    debugPrint('      수면 시작: ${startSleep.toString()}');
    debugPrint('      수면 종료: ${endSleep.toString()}');

    // STEP 2.5. 주간 스케줄의 모든 날짜에서 근무 시간대와 겹치는지 확인
    if (weeklySchedule != null) {
      final todayKey = getTodayKey(dayStartHour);
      
      // 최근 7일 동안의 모든 날짜를 확인
      for (int i = -3; i <= 3; i++) {
        final checkDate = todayKey.add(Duration(days: i));
        final checkShift = weeklySchedule.getShiftForDate(checkDate);
        
        if (checkShift != null && 
            checkShift.shiftStart != null && 
            checkShift.shiftEnd != null &&
            checkShift.type != ShiftType.off) {
          
          // 저장된 날짜 정보를 그대로 사용
          DateTime actualWorkStart = checkShift.shiftStart!;
          DateTime actualWorkEnd = checkShift.shiftEnd!;
          
          // 종료 시간이 시작 시간보다 이전이면 다음날로 해석
          if (actualWorkEnd.isBefore(actualWorkStart) || actualWorkEnd == actualWorkStart) {
            actualWorkEnd = actualWorkEnd.add(const Duration(days: 1));
          }
          
          // 수면 시간이 근무 시간대와 겹치는지 확인
          final sleepOverlapsWork = (startSleep.isBefore(actualWorkEnd) && endSleep.isAfter(actualWorkStart));
          
          if (sleepOverlapsWork) {
            debugPrint('   ⚠️ 계산된 수면 시간이 근무 시간대와 겹침:');
            debugPrint('      수면: ${startSleep.toString()} ~ ${endSleep.toString()}');
            debugPrint('      근무: ${actualWorkStart.toString()} ~ ${actualWorkEnd.toString()}');
            debugPrint('      날짜: ${checkDate.toString()}');
            
            // 수면 시간을 근무 시간대 밖으로 조정
            if (endSleep.isAfter(actualWorkStart) && startSleep.isBefore(actualWorkStart)) {
              // 수면 종료 시간이 근무 시작 시간과 겹치는 경우
              // 수면 시작 시간을 앞당겨서 근무 시작 전에 끝나도록 조정
              final sleepDuration = endSleep.difference(startSleep);
              startSleep = actualWorkStart.subtract(sleepDuration);
              endSleep = actualWorkStart;
              debugPrint('      → 수면 시간 조정: ${startSleep.toString()} ~ ${endSleep.toString()}');
            } else if (startSleep.isBefore(actualWorkEnd) && endSleep.isAfter(actualWorkEnd)) {
              // 수면 시작 시간이 근무 종료 시간과 겹치는 경우
              // 수면 시작 시간을 근무 종료 후로 미룸
              final sleepDuration = endSleep.difference(startSleep);
              startSleep = actualWorkEnd;
              endSleep = actualWorkEnd.add(sleepDuration);
              debugPrint('      → 수면 시간 조정: ${startSleep.toString()} ~ ${endSleep.toString()}');
            } else if (startSleep.isAfter(actualWorkStart) && endSleep.isBefore(actualWorkEnd)) {
              // 수면 시간이 완전히 근무 시간대 안에 있는 경우
              // 수면을 근무 종료 후로 이동
              final sleepDuration = endSleep.difference(startSleep);
              startSleep = actualWorkEnd;
              endSleep = actualWorkEnd.add(sleepDuration);
              debugPrint('      → 수면 시간 조정 (근무 후): ${startSleep.toString()} ~ ${endSleep.toString()}');
            }
          }
        }
      }
      
      debugPrint('   ✅ 근무 시간대 겹침 확인 완료');
      debugPrint('      최종 수면: ${startSleep.toString()} ~ ${endSleep.toString()}');
    }

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