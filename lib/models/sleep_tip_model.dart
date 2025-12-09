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
  // All available tips for auto-rotation
  static const List<SleepTip> _allTips = [
    SleepTip(
      title: '☀️ 아침 햇빛',
      description:
          '기상 후 1시간 이내에 10-15분간 자연광을 받아 생체리듬을 조절하세요.',
      icon: Icons.wb_sunny,
      timeLabel: '아침 루틴',
      gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    SleepTip(
      title: '☕ 카페인 컷오프',
      description:
          '오후 2시 이후에는 카페인을 피하세요. 카페인의 반감기는 5-6시간이며 수면을 방해할 수 있습니다.',
      icon: Icons.coffee,
      timeLabel: '오후 주의',
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    SleepTip(
      title: '🌙 취침 준비',
      description:
          '수면 1-2시간 전부터 취침 준비를 시작하세요. 조명을 어둡게 하고 화면 사용을 줄이세요.',
      icon: Icons.nightlight_round,
      timeLabel: '저녁 준비',
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
    ),
    SleepTip(
      title: '😴 수면 시간',
      description:
          '침실은 시원하게(15-19°C), 어둡고 조용하게 유지하세요. 수면 마스크나 백색 소음을 고려해보세요.',
      icon: Icons.bedtime,
      timeLabel: '밤 시간',
      gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
    SleepTip(
      title: '⏰ 규칙적인 일정',
      description:
          '매일 같은 시간에 잠자리에 들고 일어나세요. 주말에도 일정을 유지하는 것이 좋습니다.',
      icon: Icons.schedule,
      timeLabel: '일상 습관',
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    SleepTip(
      title: '🏃 규칙적인 운동',
      description:
          '규칙적으로 운동하되, 취침 최소 3시간 전에는 운동을 마치세요.',
      icon: Icons.fitness_center,
      timeLabel: '신체 건강',
      gradientColors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
    ),
    SleepTip(
      title: '🍽️ 가벼운 저녁식사',
      description:
          '취침 2-3시간 전에는 무거운 식사를 피하세요. 배가 고프면 가벼운 간식을 드세요.',
      icon: Icons.restaurant,
      timeLabel: '저녁 식사',
      gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    SleepTip(
      title: '📱 화면 사용 시간',
      description:
          '취침 1시간 전에는 화면을 끄세요. 파란 빛은 멜라토닌 생성을 억제합니다.',
      icon: Icons.phone_iphone,
      timeLabel: '디지털 디톡스',
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
    ),
    SleepTip(
      title: '🧘 휴식',
      description:
          '명상, 깊은 호흡, 부드러운 요가 같은 휴식 기법을 실천하세요.',
      icon: Icons.self_improvement,
      timeLabel: '마음과 몸',
      gradientColors: [Color(0xFF7F7FD5), Color(0xFF91EAE4)],
    ),
    SleepTip(
      title: '🌡️ 시원한 방',
      description:
          '최적의 수면을 위해 침실 온도를 15-19°C로 유지하세요.',
      icon: Icons.thermostat,
      timeLabel: '환경',
      gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
    SleepTip(
      title: '🛏️ 침대 = 수면',
      description:
          '침대는 수면에만 사용하세요. 침대에서 일하거나 TV를 보는 것을 피하세요.',
      icon: Icons.hotel,
      timeLabel: '수면 연상',
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    SleepTip(
      title: '💤 20분 규칙',
      description:
          '20분 후에도 잠이 오지 않으면 일어나서 편안한 활동을 하세요.',
      icon: Icons.timer,
      timeLabel: '수면 전략',
      gradientColors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
    ),
    SleepTip(
      title: '🚫 알코올 제한',
      description:
          '취침 전 알코올을 피하세요. REM 수면을 방해하고 단편적인 수면을 유발합니다.',
      icon: Icons.no_drinks,
      timeLabel: '저녁 루틴',
      gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    SleepTip(
      title: '☕ 아침 커피',
      description:
          '커피는 아침에 마시세요. 기상 후 90분을 기다리면 최적의 효과를 얻을 수 있습니다.',
      icon: Icons.coffee_maker,
      timeLabel: '아침 활력',
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
    ),
    SleepTip(
      title: '😌 스트레스 관리',
      description:
          '취침 전 걱정거리를 적어보세요. 일기나 내일 할 일 목록을 작성하세요.',
      icon: Icons.book,
      timeLabel: '정신 건강',
      gradientColors: [Color(0xFF7F7FD5), Color(0xFF91EAE4)],
    ),
    SleepTip(
      title: '🌅 자연광',
      description:
          '낮 동안 밝은 빛에 노출되어 건강한 수면-각성 주기를 유지하세요.',
      icon: Icons.light_mode,
      timeLabel: '낮 시간 습관',
      gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
  ];

  // 시간대별 팁 분류
  // 아침: 5-11시
  static const List<int> _morningTips = [0, 14, 15]; // 아침 햇빛, 아침 커피, 자연광
  
  // 점심: 12-15시
  static const List<int> _afternoonTips = [1, 4, 5]; // 카페인 컷오프, 규칙적인 일정, 규칙적인 운동
  
  // 저녁: 16-20시
  static const List<int> _eveningTips = [2, 6, 7, 8, 9, 11, 12]; // 취침 준비, 가벼운 저녁식사, 화면 사용 시간, 휴식, 시원한 방, 알코올 제한, 스트레스 관리
  
  // 밤: 21-4시
  static const List<int> _nightTips = [3, 4, 5, 10, 13]; // 수면 시간, 규칙적인 일정, 규칙적인 운동, 침대=수면, 20분 규칙

  /// 현재 시간대에 맞는 팁 인덱스 리스트 가져오기
  static List<int> _getTipsForCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return _morningTips;
    } else if (hour >= 12 && hour < 16) {
      return _afternoonTips;
    } else if (hour >= 16 && hour < 21) {
      return _eveningTips;
    } else {
      return _nightTips;
    }
  }

  /// 현재 시간대에 맞는 모든 팁을 랜덤 순서로 가져오기
  static List<SleepTip> getTimeBasedTipsShuffled() {
    final tipIndices = _getTipsForCurrentTime();
    // 랜덤 셔플 (시드 기반으로 일관성 유지)
    final shuffled = List<int>.from(tipIndices);
    shuffled.shuffle();
    return shuffled.map((index) => _allTips[index]).toList();
  }

  /// 현재 시간대에 맞는 랜덤 팁 가져오기
  static SleepTip getTimeBasedRandomTip() {
    final tipsForTime = _getTipsForCurrentTime();
    // 랜덤 선택
    final random = DateTime.now().millisecondsSinceEpoch % tipsForTime.length;
    final tipIndex = tipsForTime[random];
    return _allTips[tipIndex];
  }

  /// Get time-based tip based on current hour (기존 메서드 유지 - 호환성)
  static SleepTip getTimeBasedTip() {
    return getTimeBasedRandomTip();
  }

  /// Get rotating tip based on time (changes every 10 seconds for demo)
  static SleepTip getRotatingTip() {
    final totalSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final index = totalSeconds % _allTips.length;
    return _allTips[index];
  }

  /// Get random tip from all available tips
  static SleepTip getRandomTip() {
    final random = DateTime.now().microsecond % _allTips.length;
    return _allTips[random];
  }

  /// Get next tip in sequence (useful for manual navigation)
  static SleepTip getNextTip(SleepTip currentTip) {
    final currentIndex = _allTips.indexOf(currentTip);
    final nextIndex = (currentIndex + 1) % _allTips.length;
    return _allTips[nextIndex];
  }

  /// Get previous tip in sequence
  static SleepTip getPreviousTip(SleepTip currentTip) {
    final currentIndex = _allTips.indexOf(currentTip);
    final previousIndex = (currentIndex - 1 + _allTips.length) % _allTips.length;
    return _allTips[previousIndex];
  }


  // Sleep hygiene recommendations (legacy - use getRandomTip or getRotatingTip instead)
  static List<SleepTip> get hygieneRecommendations => _allTips;

  // Best practices for sleep (legacy - use getRandomTip or getRotatingTip instead)
  static List<SleepTip> get bestPractices => _allTips;
}
