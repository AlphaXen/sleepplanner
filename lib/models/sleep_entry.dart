class SleepEntry {
  final String? id; // Firestore 문서 ID
  final DateTime sleepTime;
  final DateTime wakeTime;
  final bool isNightShift;

  SleepEntry({
    this.id,
    required this.sleepTime,
    required this.wakeTime,
    required this.isNightShift,
  });

  Duration get duration => wakeTime.difference(sleepTime);

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  /// 수면이 속한 날짜 (기상 시간 기준)
  /// 야간 근무자의 경우 자정을 넘어서 자므로 기상한 날을 기준으로 함
  DateTime get dateKey => DateTime(wakeTime.year, wakeTime.month, wakeTime.day);

  Map<String, dynamic> toJson() => {
        'sleepTime': sleepTime.toIso8601String(),
        'wakeTime': wakeTime.toIso8601String(),
        'isNightShift': isNightShift,
      };

  factory SleepEntry.fromJson(String id, Map<String, dynamic> json) {
    return SleepEntry(
      id: id,
      sleepTime: DateTime.parse(json['sleepTime']),
      wakeTime: DateTime.parse(json['wakeTime']),
      isNightShift: json['isNightShift'] ?? false,
    );
  }

  SleepEntry copyWith({
    String? id,
    DateTime? sleepTime,
    DateTime? wakeTime,
    bool? isNightShift,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      sleepTime: sleepTime ?? this.sleepTime,
      wakeTime: wakeTime ?? this.wakeTime,
      isNightShift: isNightShift ?? this.isNightShift,
    );
  }
}
