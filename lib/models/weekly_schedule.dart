import 'shift_info.dart';

/// 주간 근무 스케줄
class WeeklySchedule {
  final DateTime weekStart; // 월요일 기준
  final Map<int, ShiftInfo> shifts; // 0=월요일, 6=일요일

  WeeklySchedule({
    required this.weekStart,
    required this.shifts,
  });

  /// 특정 날짜의 근무 정보 가져오기
  /// 주의: 같은 주 내의 날짜만 정확하게 매칭됩니다
  ShiftInfo? getShiftForDate(DateTime date) {
    // 주간 스케줄의 weekStart와 입력 날짜가 같은 주인지 확인
    final daysFromWeekStart = date.difference(weekStart).inDays;
    
    // 같은 주 내에 있는지 확인 (0-6일 사이)
    if (daysFromWeekStart >= 0 && daysFromWeekStart < 7) {
      final dayOfWeek = date.weekday - 1; // 0=월, 6=일
      return shifts[dayOfWeek];
    }
    
    // 다른 주면 요일만 매칭 (임시)
    final dayOfWeek = date.weekday - 1;
    return shifts[dayOfWeek];
  }

  /// 야간 근무 일수 계산
  int get nightShiftCount {
    return shifts.values.where((s) => s.type == ShiftType.night).length;
  }

  /// 주간 근무 일수 계산
  int get dayShiftCount {
    return shifts.values.where((s) => s.type == ShiftType.day).length;
  }

  /// 휴무 일수 계산
  int get offDaysCount {
    return shifts.values.where((s) => s.type == ShiftType.off).length;
  }

  /// 근무 패턴 감지 (예: "3야간-2휴무-2주간")
  String detectPattern() {
    final pattern = <String>[];
    String? lastType;
    int count = 0;

    for (int i = 0; i < 7; i++) {
      final shift = shifts[i];
      if (shift == null) continue;

      final type = shift.type.name;
      if (type == lastType) {
        count++;
      } else {
        if (lastType != null) {
          pattern.add('$count${_getTypeKorean(lastType)}');
        }
        lastType = type;
        count = 1;
      }
    }

    if (lastType != null) {
      pattern.add('$count${_getTypeKorean(lastType)}');
    }

    return pattern.join('-');
  }

  String _getTypeKorean(String type) {
    switch (type) {
      case 'day':
        return '주간';
      case 'night':
        return '야간';
      case 'off':
        return '휴무';
      default:
        return type;
    }
  }

  Map<String, dynamic> toJson() => {
        'weekStart': weekStart.toIso8601String(),
        'shifts': shifts.map((key, value) => MapEntry(
              key.toString(),
              {
                'type': value.type.name,
                'shiftStart': value.shiftStart?.toIso8601String(),
                'shiftEnd': value.shiftEnd?.toIso8601String(),
                'preferredMid': value.preferredMid?.toIso8601String(),
              },
            )),
      };

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final shiftsMap = <int, ShiftInfo>{};
    final shiftsData = json['shifts'] as Map<String, dynamic>;

    shiftsData.forEach((key, value) {
      final dayIndex = int.parse(key);
      final type = value['type'] as String;

      ShiftInfo shift;
      if (type == 'day') {
        shift = ShiftInfo.day(
          shiftStart: DateTime.parse(value['shiftStart']),
          shiftEnd: DateTime.parse(value['shiftEnd']),
        );
      } else if (type == 'night') {
        shift = ShiftInfo.night(
          shiftStart: DateTime.parse(value['shiftStart']),
          shiftEnd: DateTime.parse(value['shiftEnd']),
        );
      } else {
        shift = ShiftInfo.off(
          preferredMid: value['preferredMid'] != null
              ? DateTime.parse(value['preferredMid'])
              : DateTime.now(),
        );
      }
      shiftsMap[dayIndex] = shift;
    });

    return WeeklySchedule(
      weekStart: DateTime.parse(json['weekStart']),
      shifts: shiftsMap,
    );
  }
}

/// 수면 부채 추적
class SleepDebt {
  final DateTime date;
  final double targetHours; // 목표 수면 시간
  final double actualHours; // 실제 수면 시간
  final double debtHours; // 부채 (음수면 초과 수면)

  SleepDebt({
    required this.date,
    required this.targetHours,
    required this.actualHours,
  }) : debtHours = targetHours - actualHours;

  bool get hasDebt => debtHours > 0;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'targetHours': targetHours,
        'actualHours': actualHours,
        'debtHours': debtHours,
      };

  factory SleepDebt.fromJson(Map<String, dynamic> json) {
    return SleepDebt(
      date: DateTime.parse(json['date']),
      targetHours: json['targetHours'].toDouble(),
      actualHours: json['actualHours'].toDouble(),
    );
  }
}

/// 낮잠 추천
class NapRecommendation {
  final DateTime napTime;
  final Duration duration;
  final String reason;
  final NapType type;

  NapRecommendation({
    required this.napTime,
    required this.duration,
    required this.reason,
    required this.type,
  });
}

enum NapType {
  power, // 파워 낮잠 (15-20분)
  short, // 짧은 낮잠 (30-45분)
  long, // 긴 낮잠 (90분, 완전한 수면 사이클)
}

