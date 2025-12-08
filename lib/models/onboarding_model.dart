import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
  });
}

class OnboardingData {
  static const List<OnboardingPage> pages = [
    OnboardingPage(
      title: '🛌 수면 기록',
      description: '매일의 수면 시간을 기록하세요.\n앱이 당신의 수면 패턴을 분석합니다.',
      icon: Icons.bedtime,
      backgroundColor: Color(0xFF4facfe),
    ),
    OnboardingPage(
      title: '📅 일일 계획',
      description: '근무 시간을 입력하면\n최적의 수면 시간을 추천해드립니다.',
      icon: Icons.schedule,
      backgroundColor: Color(0xFF667eea),
    ),
    OnboardingPage(
      title: '📊 통계 분석',
      description: '주간 수면 그래프와 목표 달성률을\n한눈에 확인하세요.',
      icon: Icons.show_chart,
      backgroundColor: Color(0xFF11998e),
    ),
    OnboardingPage(
      title: '💡 스마트 팁',
      description: '시간대별 맞춤형 수면 조언을\n받을 수 있습니다.',
      icon: Icons.lightbulb,
      backgroundColor: Color(0xFFf093fb),
    ),
    OnboardingPage(
      title: '🎵 수면음악',
      description: '다양한 수면음악으로\n편안한 잠을 자세요.',
      icon: Icons.music_note,
      backgroundColor: Color(0xFF56ab2f),
    ),
    OnboardingPage(
      title: '🚀 시작하기',
      description: '모든 준비가 되었습니다.\n지금부터 수면 계획을 시작하세요!',
      icon: Icons.rocket_launch,
      backgroundColor: Color(0xFFff6b6b),
    ),
  ];
}
