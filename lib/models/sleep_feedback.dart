class SleepFeedback {
  final DateTime date;
  final double sleepScore; // 1.0 ~ 5.0 (수면 품질 점수)
  final double daytimeSleepiness; // 1.0 ~ 5.0 (낮 졸음 정도)
  final bool hadLateCaffeine; // 늦은 시간 카페인 섭취 여부
  final bool hadHighLightExposure; // 높은 빛 노출 여부
  final String? notes; // 사용자 메모

  SleepFeedback({
    required this.date,
    required this.sleepScore,
    required this.daytimeSleepiness,
    this.hadLateCaffeine = false,
    this.hadHighLightExposure = false,
    this.notes,
  });

  DateTime get dateKey => DateTime(date.year, date.month, date.day);

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'sleepScore': sleepScore,
        'daytimeSleepiness': daytimeSleepiness,
        'hadLateCaffeine': hadLateCaffeine,
        'hadHighLightExposure': hadHighLightExposure,
        'notes': notes,
      };

  factory SleepFeedback.fromJson(Map<String, dynamic> json) {
    return SleepFeedback(
      date: DateTime.parse(json['date']),
      sleepScore: (json['sleepScore'] ?? 3.0).toDouble(),
      daytimeSleepiness: (json['daytimeSleepiness'] ?? 3.0).toDouble(),
      hadLateCaffeine: json['hadLateCaffeine'] ?? false,
      hadHighLightExposure: json['hadHighLightExposure'] ?? false,
      notes: json['notes'],
    );
  }
}

