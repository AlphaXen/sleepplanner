import 'package:flutter/foundation.dart';
import '../models/weekly_schedule.dart';
import '../models/shift_info.dart';
import '../models/sleep_entry.dart';
import '../models/adaptive_params.dart';
import '../utils/date_utils.dart';

class ShiftWorkerService {
  /// 수면 부채 계산 (최근 N일)
  /// 기록이 없는 날은 제외됨 (0시간으로 처리하지 않음)
  List<SleepDebt> calculateSleepDebt({
    required List<SleepEntry> entries,
    required double targetHours,
    required int dayStartHour,
    int days = 7,
  }) {
    final debts = <SleepDebt>[];
    final today = getTodayKey(dayStartHour);

    debugPrint('🔍 수면부채 계산 시작:');
    debugPrint('   전체 수면 기록 수: ${entries.length}개');
    debugPrint('   목표 시간: ${targetHours}시간');
    debugPrint('   계산 기간: 최근 ${days}일');
    debugPrint('   오늘 날짜 키: ${today.toString()}');
    debugPrint('   하루 시작 시간: ${dayStartHour}시');

    // 최근 N일 계산 (오늘부터 과거로)
    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));

      // 해당 날짜의 총 수면 시간 계산
      final dayEntries = entries.where((e) {
        final entryDate = getDateKey(e.wakeTime, dayStartHour);
        final matches = entryDate.year == date.year &&
            entryDate.month == date.month &&
            entryDate.day == date.day;
        if (matches) {
          debugPrint('   ✅ 매칭: ${e.sleepTime.toString()} ~ ${e.wakeTime.toString()} (기상일: ${entryDate.toString().substring(0, 10)})');
        }
        return matches;
      }).toList();

      // 수면 기록이 있는 날만 부채 계산에 포함
      if (dayEntries.isNotEmpty) {
        double actualHours = 0;
        for (final entry in dayEntries) {
          final hours = entry.duration.inMinutes / 60.0;
          actualHours += hours;
          debugPrint('      수면 시간: ${hours.toStringAsFixed(2)}시간 (총 ${actualHours.toStringAsFixed(2)}시간)');
        }

        final debt = SleepDebt(
          date: date,
          targetHours: targetHours,
          actualHours: actualHours,
        );
        
        debugPrint('      부채: ${debt.debtHours.toStringAsFixed(2)}시간 (목표 ${targetHours}h - 실제 ${actualHours.toStringAsFixed(2)}h)');
        
        debts.add(debt);
      } else {
        debugPrint('   ⚠️ ${date.toString().substring(0, 10)}: 기록 없음 (제외)');
      }
      // 기록 없는 날은 debts 리스트에 추가하지 않음
    }

    // 최신순으로 정렬 (오늘이 첫번째)
    debts.sort((a, b) => b.date.compareTo(a.date));

    debugPrint('   최종 계산된 부채 일수: ${debts.length}일');
    debugPrint('   총 누적 부채: ${debts.fold(0.0, (sum, debt) => sum + debt.debtHours).toStringAsFixed(2)}시간');

    return debts;
  }

  /// 누적 수면 부채 계산
  double calculateCumulativeDebt(List<SleepDebt> debts) {
    return debts.fold(0.0, (sum, debt) => sum + debt.debtHours);
  }

  /// 낮잠 추천 (야간 근무자용)
  List<NapRecommendation> recommendNaps({
    required ShiftInfo todayShift,
    required ShiftInfo? tomorrowShift,
    required double sleepDebt,
    required AdaptiveParams params,
  }) {
    final recommendations = <NapRecommendation>[];
    final now = DateTime.now();

    // 야간 근무 전 낮잠
    if (todayShift.type == ShiftType.night && todayShift.shiftStart != null) {
      final shiftStart = todayShift.shiftStart!;
      
      // 근무 시작 2-3시간 전에 90분 낮잠
      if (now.isBefore(shiftStart.subtract(const Duration(hours: 3)))) {
        final napTime = shiftStart.subtract(const Duration(hours: 3));
        recommendations.add(NapRecommendation(
          napTime: napTime,
          duration: const Duration(minutes: 90),
          reason: '야간 근무 전 예방적 낮잠 (완전한 수면 사이클)',
          type: NapType.long,
        ));
      }
    }

    // 야간 근무 후 낮잠
    if (todayShift.type == ShiftType.night && todayShift.shiftEnd != null) {
      final shiftEnd = todayShift.shiftEnd!;
      
      // 근무 종료 후 1.5-2시간 이내에 메인 수면
      final mainSleepTime = shiftEnd.add(const Duration(hours: 1, minutes: 30));
      recommendations.add(NapRecommendation(
        napTime: mainSleepTime,
        duration: Duration(hours: params.tSleep.floor()),
        reason: '야간 근무 후 회복 수면 (메인 수면)',
        type: NapType.long,
      ));
    }

    // 수면 부채가 높은 경우 추가 낮잠
    if (sleepDebt > 2.0) {
      // 오후 2-3시 파워 낮잠
      final afternoonNap = DateTime(now.year, now.month, now.day, 14, 30);
      if (now.isBefore(afternoonNap)) {
        recommendations.add(NapRecommendation(
          napTime: afternoonNap,
          duration: const Duration(minutes: 20),
          reason: '수면 부채 해소를 위한 파워 낮잠',
          type: NapType.power,
        ));
      }
    }

    // 연속 야간 근무 중간
    if (todayShift.type == ShiftType.night &&
        tomorrowShift?.type == ShiftType.night) {
      recommendations.add(NapRecommendation(
        napTime: DateTime(now.year, now.month, now.day, 16, 0),
        duration: const Duration(minutes: 30),
        reason: '연속 야간 근무 중 각성 유지를 위한 짧은 낮잠',
        type: NapType.short,
      ));
    }

    return recommendations;
  }

  /// 빛 노출 전략 생성
  Map<String, dynamic> generateLightExposureStrategy({
    required ShiftInfo shift,
    required DateTime now,
  }) {
    final strategy = <String, dynamic>{};

    if (shift.type == ShiftType.night) {
      strategy['duringWork'] = {
        'intensity': 'high',
        'description': '근무 중 밝은 빛 노출 (각성 유지)',
        'recommendation': '가능한 밝은 조명 아래에서 근무하세요',
      };

      if (shift.shiftEnd != null) {
        final goHomeTime = shift.shiftEnd!;
        strategy['afterWork'] = {
          'intensity': 'block',
          'description': '퇴근 후 빛 차단 (멜라토닌 분비 유지)',
          'recommendation': '선글라스 착용, 커튼 암막 처리',
          'criticalTime': goHomeTime.toIso8601String(),
        };
      }

      strategy['beforeSleep'] = {
        'intensity': 'minimal',
        'description': '수면 전 최소 빛 노출',
        'recommendation': '어두운 환경에서 휴식',
      };
    } else if (shift.type == ShiftType.day) {
      strategy['morning'] = {
        'intensity': 'high',
        'description': '아침 햇빛 노출 (일주기 리듬 강화)',
        'recommendation': '기상 후 30분 이내 밝은 빛 노출',
      };

      strategy['evening'] = {
        'intensity': 'dim',
        'description': '저녁 빛 줄이기',
        'recommendation': '취침 2시간 전부터 조명 어둡게',
      };
    }

    return strategy;
  }

  /// 회전 근무 적응 조언
  List<String> getRotationAdaptationTips({
    required ShiftType currentShift,
    required ShiftType nextShift,
  }) {
    final tips = <String>[];

    // 주간 → 야간
    if (currentShift == ShiftType.day && nextShift == ShiftType.night) {
      tips.add('💡 점진적 수면 시간 이동: 매일 1-2시간씩 늦게 자기');
      tips.add('🌙 전환일 낮잠: 야간 근무 시작 2-3시간 전 90분 낮잠');
      tips.add('☕ 카페인 전략: 야간 근무 시작 시 섭취, 중반 이후 중단');
      tips.add('🕶️ 퇴근 시 선글라스 착용으로 빛 차단');
    }

    // 야간 → 주간
    if (currentShift == ShiftType.night && nextShift == ShiftType.day) {
      tips.add('☀️ 마지막 야근 후: 짧게 자고 오후에 기상');
      tips.add('🌅  전환일 아침 햇빛: 일주기 리듬 재설정');
      tips.add('⏰ 점진적 기상: 매일 1-2시간씩 일찍 일어나기');
      tips.add('🚫 낮잠 자제: 전환 첫날은 낮잠 피하기');
    }

    // 야간 → 휴무
    if (currentShift == ShiftType.night && nextShift == ShiftType.off) {
      tips.add('💤 회복 수면: 첫날은 충분히 자되, 너무 길게는 금물');
      tips.add('☀️ 사회적 시간 복귀: 가족과 함께하는 시간 활용');
      tips.add('🏃 가벼운 운동: 일주기 리듬 정상화 도움');
    }

    // 연속 야간 근무
    if (currentShift == ShiftType.night && nextShift == ShiftType.night) {
      tips.add('⏰ 일관된 수면 시간 유지');
      tips.add('☕ 근무 중반 이후 카페인 자제');
      tips.add('🛌 근무 사이 최소 7시간 수면 확보');
    }

    return tips;
  }

  /// 수면 부채 회복 계획
  Map<String, dynamic> createDebtRecoveryPlan({
    required double cumulativeDebt,
    required WeeklySchedule? schedule,
  }) {
    final plan = <String, dynamic>{};

    if (cumulativeDebt <= 0) {
      plan['status'] = 'good';
      plan['message'] = '수면 부채 없음! 현재 패턴 유지하세요.';
      return plan;
    }

    // 경미한 부채 (1-3시간)
    if (cumulativeDebt <= 3.0) {
      plan['status'] = 'minor';
      plan['message'] = '경미한 수면 부채 (${cumulativeDebt.toStringAsFixed(1)}시간)';
      plan['strategies'] = [
        '휴무일에 목표 수면시간보다 30-60분 더 자기',
        '20분 파워 낮잠 활용 (2-3일)',
      ];
    }
    // 중등도 부채 (3-7시간)
    else if (cumulativeDebt <= 7.0) {
      plan['status'] = 'moderate';
      plan['message'] = '중등도 수면 부채 (${cumulativeDebt.toStringAsFixed(1)}시간)';
      plan['strategies'] = [
        '다음 휴무일 1-2시간 추가 수면',
        '야간 근무 전 90분 예방적 낮잠',
        '일주일 동안 매일 30분씩 일찍 취침',
      ];
    }
    // 심각한 부채 (7시간 이상)
    else {
      plan['status'] = 'severe';
      plan['message'] = '심각한 수면 부채 (${cumulativeDebt.toStringAsFixed(1)}시간) ⚠️';
      plan['strategies'] = [
        '🚨 가능하면 연속 휴무 2-3일 확보',
        '전문의 상담 고려 (수면 장애 가능성)',
        '근무 패턴 재조정 필요',
        '회복 기간 동안 카페인 최소화',
      ];
    }

    // 예상 회복 기간
    final recoveryDays = (cumulativeDebt / 1.5).ceil();
    plan['recoveryDays'] = recoveryDays;
    plan['recoveryMessage'] =
        '예상 회복 기간: 약 $recoveryDays일 (하루 1-2시간 추가 수면 시)';

    return plan;
  }

  /// 수면 일관성 계산 (표준편차 기반)
  double calculateSleepConsistency(List<SleepDebt> debts) {
    if (debts.length < 2) return 1.0;

    final sleepHours = debts.map((d) => d.actualHours).toList();
    final mean = sleepHours.reduce((a, b) => a + b) / sleepHours.length;

    double sumSquaredDiff = 0;
    for (final hours in sleepHours) {
      sumSquaredDiff += (hours - mean) * (hours - mean);
    }

    final stdDev = (sumSquaredDiff / sleepHours.length).abs().clamp(0.0, double.infinity);
    final variance = stdDev > 0 ? stdDev : 0.0;

    // 표준편차가 2시간 이상이면 0, 0시간이면 1
    return (1 - (variance / 2.0)).clamp(0.0, 1.0);
  }

  /// 연속 야간 근무 일수 계산
  int calculateConsecutiveNightShifts(WeeklySchedule? schedule) {
    if (schedule == null) return 0;

    int maxConsecutive = 0;
    int currentConsecutive = 0;

    for (int i = 0; i < 7; i++) {
      final shift = schedule.shifts[i];
      if (shift != null && shift.type == ShiftType.night) {
        currentConsecutive++;
        if (currentConsecutive > maxConsecutive) {
          maxConsecutive = currentConsecutive;
        }
      } else {
        currentConsecutive = 0;
      }
    }

    return maxConsecutive;
  }

  /// 야간 노동자 건강 점수 계산
  double calculateShiftWorkerHealthScore({
    required double avgSleepHours,
    required double sleepDebt,
    required double sleepConsistency,
    required int consecutiveNightShifts,
  }) {
    double score = 100.0;

    // 평균 수면 시간 (30점)
    if (avgSleepHours < 6.0) {
      score -= 30;
    } else if (avgSleepHours < 7.0) {
      score -= 15;
    } else if (avgSleepHours > 9.0) {
      score -= 10;
    }

    // 수면 부채 (30점)
    if (sleepDebt > 7.0) {
      score -= 30;
    } else if (sleepDebt > 3.0) {
      score -= 15;
    } else if (sleepDebt > 0) {
      score -= 5;
    }

    // 수면 일관성 (20점)
    score += sleepConsistency * 20;

    // 연속 야간 근무 (20점)
    if (consecutiveNightShifts > 5) {
      score -= 20;
    } else if (consecutiveNightShifts > 3) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }
}

