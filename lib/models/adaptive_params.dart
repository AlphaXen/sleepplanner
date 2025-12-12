class AdaptiveParams {
  double tSleep;
  double cafWindow;
  int winddownMinutes;
  double chronoOffset;
  double lightSens;
  double cafSens;

  AdaptiveParams({
    this.tSleep = 7.0,
    this.cafWindow = 6.0,
    this.winddownMinutes = 60,
    this.chronoOffset = 0.0,
    this.lightSens = 0.5,
    this.cafSens = 0.5,
  });

  AdaptiveParams copyWith({
    double? tSleep,
    double? cafWindow,
    int? winddownMinutes,
    double? chronoOffset,
    double? lightSens,
    double? cafSens,
  }) {
    return AdaptiveParams(
      tSleep: tSleep ?? this.tSleep,
      cafWindow: cafWindow ?? this.cafWindow,
      winddownMinutes: winddownMinutes ?? this.winddownMinutes,
      chronoOffset: chronoOffset ?? this.chronoOffset,
      lightSens: lightSens ?? this.lightSens,
      cafSens: cafSens ?? this.cafSens,
    );
  }

  Map<String, dynamic> toJson() => {
        'tSleep': tSleep,
        'cafWindow': cafWindow,
        'winddownMinutes': winddownMinutes,
        'chronoOffset': chronoOffset,
        'lightSens': lightSens,
        'cafSens': cafSens,
      };

  factory AdaptiveParams.fromJson(Map<String, dynamic> json) {
    return AdaptiveParams(
      tSleep: (json['tSleep'] ?? 7.0).toDouble(),
      cafWindow: (json['cafWindow'] ?? 6.0).toDouble(),
      winddownMinutes: (json['winddownMinutes'] ?? 60).toInt(),
      chronoOffset: (json['chronoOffset'] ?? 0.0).toDouble(),
      lightSens: (json['lightSens'] ?? 0.5).toDouble(),
      cafSens: (json['cafSens'] ?? 0.5).toDouble(),
    );
  }
}
