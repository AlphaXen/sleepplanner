enum ShiftType { day, night, off }

class ShiftInfo {
  final ShiftType type;
  final DateTime? shiftStart;
  final DateTime? shiftEnd;

  /// 휴무일 mid-sleep 기준
  final DateTime? preferredMid;

  ShiftInfo.day({
    required this.shiftStart,
    required this.shiftEnd,
  })  : type = ShiftType.day,
        preferredMid = null;

  ShiftInfo.night({
    required this.shiftStart,
    required this.shiftEnd,
  })  : type = ShiftType.night,
        preferredMid = null;

  ShiftInfo.off({
    required this.preferredMid,
  })  : type = ShiftType.off,
        shiftStart = null,
        shiftEnd = null;
}
