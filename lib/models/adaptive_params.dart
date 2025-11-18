class AdaptiveParams {
  /// 목표 수면시간 (단위: 시간, 기본 7.0h)
  double tSleep;

  /// 수면 몇 시간 전부터 카페인 금지할지 (단위: 시간)
  double cafWindow;

  /// 취침 준비 시작 시간 (단위: 분)
  int winddownMinutes;

  /// 크로노타입 오프셋 (시간 단위, 음수/양수)
  double chronoOffset;

  /// 빛 민감도 (0.0 ~ 1.0)
  double lightSens;

  /// 카페인 민감도 (0.0 ~ 1.0)
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
