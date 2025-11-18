class DailyPlan {
  final DateTime mainSleepStart;
  final DateTime mainSleepEnd;
  final DateTime caffeineCutoff;
  final DateTime winddownStart;
  final Map<String, dynamic> lightPlan;
  final List<String> notes;

  DailyPlan({
    required this.mainSleepStart,
    required this.mainSleepEnd,
    required this.caffeineCutoff,
    required this.winddownStart,
    required this.lightPlan,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'main_sleep': {
          'start': mainSleepStart.toIso8601String(),
          'end': mainSleepEnd.toIso8601String(),
        },
        'caffeine_cutoff': caffeineCutoff.toIso8601String(),
        'winddown_start': winddownStart.toIso8601String(),
        'light_plan': lightPlan,
        'notes': notes,
      };
}
