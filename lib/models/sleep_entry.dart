class SleepEntry {
  final DateTime sleepTime;
  final DateTime wakeTime;
  final bool isNightShift;

  SleepEntry({
    required this.sleepTime,
    required this.wakeTime,
    required this.isNightShift,
  });

  Duration get duration => wakeTime.difference(sleepTime);

  String get formattedDuration {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return '\${h}h \${m}m';
  }

  DateTime get dateKey => DateTime(sleepTime.year, sleepTime.month, sleepTime.day);
}
