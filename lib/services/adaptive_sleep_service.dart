import 'dart:math';
import '../models/adaptive_params.dart';
import '../models/shift_info.dart';
import '../models/daily_plan.dart';

class AdaptiveSleepService {
  /// 하루 단위 추천 (Daily Recommendation)
  DailyPlan computeDailyPlan({
    required AdaptiveParams params,
    required ShiftInfo shift,
  }) {
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
          final end = shift.shiftEnd!;
          const bufferHours = 1.5;
          final buffer = Duration(
            hours: bufferHours.floor(),
            minutes: ((bufferHours % 1) * 60).round(),
          );
          final chrono = Duration(
            hours: params.chronoOffset.floor(),
            minutes: ((params.chronoOffset % 1) * 60).round(),
          );
          startSleep = end.add(buffer).add(chrono);
          endSleep = startSleep.add(tSleep);
          break;
        }
      case ShiftType.day:
        {
          final start = shift.shiftStart!;
          const beforeWork = Duration(hours: 1);
          endSleep = start.subtract(beforeWork);
          final chrono = Duration(
            hours: params.chronoOffset.floor(),
            minutes: ((params.chronoOffset % 1) * 60).round(),
          );
          startSleep = endSleep.subtract(tSleep).add(chrono);
          break;
        }
      case ShiftType.off:
        {
          final mid = shift.preferredMid ?? DateTime.now().add(const Duration(hours: 3));
          startSleep = mid.subtract(tSleep ~/ 2);
          endSleep = mid.add(tSleep ~/ 2);
          break;
        }
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
    final local = dt.toLocal();
    return "${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
  }
}