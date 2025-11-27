import 'package:flutter/material.dart';

class SleepTip {
  final String title;
  final String description;
  final IconData icon;
  final String timeLabel;
  final List<Color> gradientColors;

  const SleepTip({
    required this.title,
    required this.description,
    required this.icon,
    required this.timeLabel,
    required this.gradientColors,
  });
}

class SleepTips {
  // Time-based dynamic tips
  static SleepTip getTimeBasedTip() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return const SleepTip(
        title: '☀️ Morning Sunlight',
        description:
            'Get 10-15 minutes of natural sunlight within an hour of waking up to regulate your circadian rhythm.',
        icon: Icons.wb_sunny,
        timeLabel: 'Morning Routine',
        gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      );
    } else if (hour >= 12 && hour < 16) {
      return const SleepTip(
        title: '☕ Caffeine Cutoff',
        description:
            'Avoid caffeine after 2 PM. Caffeine has a half-life of 5-6 hours and can disrupt your sleep.',
        icon: Icons.coffee,
        timeLabel: 'Afternoon Alert',
        gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
      );
    } else if (hour >= 16 && hour < 21) {
      return const SleepTip(
        title: '🌙 Wind Down',
        description:
            'Start your bedtime routine 1-2 hours before sleep. Dim lights and reduce screen time.',
        icon: Icons.nightlight_round,
        timeLabel: 'Evening Prep',
        gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
      );
    } else {
      return const SleepTip(
        title: '😴 Sleep Time',
        description:
            'Your bedroom should be cool (60-67°F), dark, and quiet. Consider using a sleep mask or white noise.',
        icon: Icons.bedtime,
        timeLabel: 'Night Time',
        gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      );
    }
  }

  // Sleep hygiene recommendations
  static const List<SleepTip> hygieneRecommendations = [
    SleepTip(
      title: '⏰ Consistent Schedule',
      description:
          'Go to bed and wake up at the same time every day, even on weekends.',
      icon: Icons.schedule,
      timeLabel: 'Daily Habit',
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    SleepTip(
      title: '🏃 Regular Exercise',
      description:
          'Exercise regularly, but finish at least 3 hours before bedtime.',
      icon: Icons.fitness_center,
      timeLabel: 'Physical Health',
      gradientColors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
    ),
    SleepTip(
      title: '🍽️ Light Dinner',
      description:
          'Avoid heavy meals 2-3 hours before bed. Try a light snack if hungry.',
      icon: Icons.restaurant,
      timeLabel: 'Evening Meal',
      gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    SleepTip(
      title: '📱 Screen Time',
      description:
          'Turn off screens 1 hour before bed. Blue light suppresses melatonin production.',
      icon: Icons.phone_iphone,
      timeLabel: 'Digital Detox',
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
    ),
    SleepTip(
      title: '🧘 Relaxation',
      description:
          'Practice relaxation techniques like meditation, deep breathing, or gentle yoga.',
      icon: Icons.self_improvement,
      timeLabel: 'Mind & Body',
      gradientColors: [Color(0xFF7F7FD5), Color(0xFF91EAE4)],
    ),
    SleepTip(
      title: '🌡️ Cool Room',
      description:
          'Keep your bedroom between 60-67°F (15-19°C) for optimal sleep.',
      icon: Icons.thermostat,
      timeLabel: 'Environment',
      gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
  ];

  // Best practices for sleep
  static const List<SleepTip> bestPractices = [
    SleepTip(
      title: '🛏️ Bed = Sleep',
      description:
          'Use your bed only for sleep. Avoid working or watching TV in bed.',
      icon: Icons.hotel,
      timeLabel: 'Sleep Association',
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    SleepTip(
      title: '💤 20-Minute Rule',
      description:
          'If you can\'t sleep after 20 minutes, get up and do a relaxing activity.',
      icon: Icons.timer,
      timeLabel: 'Sleep Strategy',
      gradientColors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
    ),
    SleepTip(
      title: '🚫 Alcohol Limit',
      description:
          'Avoid alcohol before bed. It disrupts REM sleep and causes fragmented sleep.',
      icon: Icons.no_drinks,
      timeLabel: 'Evening Routine',
      gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    SleepTip(
      title: '☕ Morning Coffee',
      description:
          'Have your coffee in the morning. Wait 90 minutes after waking for optimal effect.',
      icon: Icons.coffee_maker,
      timeLabel: 'Morning Boost',
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
    ),
    SleepTip(
      title: '😌 Stress Management',
      description:
          'Write down worries before bed. Keep a journal or to-do list for tomorrow.',
      icon: Icons.book,
      timeLabel: 'Mental Health',
      gradientColors: [Color(0xFF7F7FD5), Color(0xFF91EAE4)],
    ),
    SleepTip(
      title: '🌅 Natural Light',
      description:
          'Expose yourself to bright light during the day to maintain healthy sleep-wake cycles.',
      icon: Icons.light_mode,
      timeLabel: 'Daytime Habit',
      gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
  ];
}
