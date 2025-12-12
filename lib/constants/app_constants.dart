class AppConstants {
  static const String appName = 'Sleep Planner';
  static const String appVersion = '1.0.1';

  static const double minSleepHours = 5.5;
  static const double maxSleepHours = 9.0;
  static const double defaultSleepHours = 7.0;

  static const double defaultCaffeineCutoffWindow = 6.0;
  static const double minCaffeineSensitivity = 0.0;
  static const double maxCaffeineSensitivity = 1.0;

  static const double minLightSensitivity = 0.0;
  static const double maxLightSensitivity = 1.0;

  static const int defaultWinddownMinutes = 30;

  static const double adaptationLearningRate = 0.2;

  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 12.0;
  static const double cardBorderRadius = 12.0;

  static const Duration shiftBuffer = Duration(hours: 1, minutes: 30);
  static const Duration preShiftWakeup = Duration(hours: 1);
}
