import 'dart:math';
import '../models/sleep_entry.dart';
import '../models/sleep_feedback.dart';
import '../models/env_sample.dart';
import '../models/adaptive_params.dart';

class SleepAnalysisResult {
  final double averageSleepHours;
  final double sleepConsistency;
  final double averageSleepScore;
  final double averageDaytimeSleepiness;
  final Map<String, double> environmentCorrelation;
  final List<String> insights;
  final List<String> recommendations;
  final AdaptiveParams currentParams;
  final Map<String, dynamic> trendData;

  SleepAnalysisResult({
    required this.averageSleepHours,
    required this.sleepConsistency,
    required this.averageSleepScore,
    required this.averageDaytimeSleepiness,
    required this.environmentCorrelation,
    required this.insights,
    required this.recommendations,
    required this.currentParams,
    required this.trendData,
  });
}

class SleepAnalysisService {
  SleepAnalysisResult analyzeSleep({
    required List<SleepEntry> sleepEntries,
    required List<SleepFeedback> feedbacks,
    required List<EnvSample> envSamples,
    required AdaptiveParams adaptiveParams,
    int analysisWindowDays = 7,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: analysisWindowDays));
    final recentEntries = sleepEntries
        .where((e) => e.sleepTime.isAfter(cutoff))
        .toList();
    final recentFeedbacks = feedbacks
        .where((f) => f.date.isAfter(cutoff))
        .toList();

    final avgSleepHours = _calculateAverageSleepHours(recentEntries);
    final sleepConsistency = _calculateSleepConsistency(recentEntries);
    final avgSleepScore = recentFeedbacks.isEmpty
        ? 3.0
        : recentFeedbacks.map((f) => f.sleepScore).reduce((a, b) => a + b) /
            recentFeedbacks.length;

    final avgDaytimeSleepiness = recentFeedbacks.isEmpty
        ? 3.0
        : recentFeedbacks
                .map((f) => f.daytimeSleepiness)
                .reduce((a, b) => a + b) /
            recentFeedbacks.length;

    final envCorrelation = _analyzeEnvironmentCorrelation(
      feedbacks: recentFeedbacks,
      envSamples: envSamples,
    );

    final insights = _generateInsights(
      avgSleepHours: avgSleepHours,
      sleepConsistency: sleepConsistency,
      avgSleepScore: avgSleepScore,
      avgDaytimeSleepiness: avgDaytimeSleepiness,
      feedbacks: recentFeedbacks,
      adaptiveParams: adaptiveParams,
    );

    final recommendations = _generateRecommendations(
      avgSleepHours: avgSleepHours,
      sleepConsistency: sleepConsistency,
      avgSleepScore: avgSleepScore,
      avgDaytimeSleepiness: avgDaytimeSleepiness,
      envCorrelation: envCorrelation,
      feedbacks: recentFeedbacks,
      adaptiveParams: adaptiveParams,
    );

    final trendData = _generateTrendData(recentEntries, recentFeedbacks);

    return SleepAnalysisResult(
      averageSleepHours: avgSleepHours,
      sleepConsistency: sleepConsistency,
      averageSleepScore: avgSleepScore,
      averageDaytimeSleepiness: avgDaytimeSleepiness,
      environmentCorrelation: envCorrelation,
      insights: insights,
      recommendations: recommendations,
      currentParams: adaptiveParams,
      trendData: trendData,
    );
  }

  double _calculateAverageSleepHours(List<SleepEntry> entries) {
    if (entries.isEmpty) return 0.0;
    final totalMinutes = entries
        .map((e) => e.duration.inMinutes)
        .reduce((a, b) => a + b);
    return totalMinutes / entries.length / 60.0;
  }

  double _calculateSleepConsistency(List<SleepEntry> entries) {
    if (entries.length < 2) return 1.0;

    final sleepHours = entries.map((e) => e.duration.inMinutes / 60.0).toList();
    final mean = sleepHours.reduce((a, b) => a + b) / sleepHours.length;

    double sumSquaredDiff = 0;
    for (final hours in sleepHours) {
      sumSquaredDiff += pow(hours - mean, 2);
    }

    final stdDev = sqrt(sumSquaredDiff / sleepHours.length);

    return (1 - (stdDev / 2.0)).clamp(0.0, 1.0);
  }

  Map<String, double> _analyzeEnvironmentCorrelation(
      {required List<SleepFeedback> feedbacks,
      required List<EnvSample> envSamples}) {
    
    double avgLux = 0;
    double avgNoise = 0;
    if (envSamples.isNotEmpty) {
      avgLux = envSamples.map((e) => e.lux).reduce((a, b) => a + b) /
          envSamples.length;
      avgNoise = envSamples.map((e) => e.noiseDb).reduce((a, b) => a + b) /
          envSamples.length;
    }

    // 카페인 영향 분석
    final caffeineImpact = _analyzeCaffeineImpact(feedbacks);

    // 빛 노출 영향 분석
    final lightImpact = _analyzeLightImpact(feedbacks);

    return {
      'avgLux': avgLux,
      'avgNoise': avgNoise,
      'caffeineImpact': caffeineImpact,
      'lightImpact': lightImpact,
    };
  }

  double _analyzeCaffeineImpact(List<SleepFeedback> feedbacks) {
    if (feedbacks.isEmpty) return 0.0;

    final withCaf = feedbacks.where((f) => f.hadLateCaffeine);
    final withoutCaf = feedbacks.where((f) => !f.hadLateCaffeine);

    if (withCaf.isEmpty || withoutCaf.isEmpty) return 0.0;

    final avgWithCaf = withCaf.map((f) => f.sleepScore).reduce((a, b) => a + b) /
        withCaf.length;
    final avgWithoutCaf = withoutCaf.map((f) => f.sleepScore).reduce((a, b) => a + b) /
        withoutCaf.length;

    // 차이 (음수면 카페인이 수면 품질 저하)
    return avgWithoutCaf - avgWithCaf;
  }

  double _analyzeLightImpact(List<SleepFeedback> feedbacks) {
    if (feedbacks.isEmpty) return 0.0;

    final withLight = feedbacks.where((f) => f.hadHighLightExposure);
    final withoutLight = feedbacks.where((f) => !f.hadHighLightExposure);

    if (withLight.isEmpty || withoutLight.isEmpty) return 0.0;

    final avgWithLight = withLight.map((f) => f.sleepScore).reduce((a, b) => a + b) /
        withLight.length;
    final avgWithoutLight = withoutLight.map((f) => f.sleepScore).reduce((a, b) => a + b) /
        withoutLight.length;

    return avgWithoutLight - avgWithLight;
  }

  List<String> _generateInsights({
    required double avgSleepHours,
    required double sleepConsistency,
    required double avgSleepScore,
    required double avgDaytimeSleepiness,
    required List<SleepFeedback> feedbacks,
    required AdaptiveParams adaptiveParams,
  }) {
    final insights = <String>[];

    // 수면 시간 분석
    if (avgSleepHours < 6.5) {
      insights.add('⚠️ 평균 수면 시간이 부족합니다. 목표 ${adaptiveParams.tSleep.toStringAsFixed(1)}시간보다 ${(adaptiveParams.tSleep - avgSleepHours).toStringAsFixed(1)}시간 부족해요.');
    } else if (avgSleepHours >= 7.0 && avgSleepHours <= 9.0) {
      insights.add('✅ 적정 수면 시간을 유지하고 있습니다!');
    } else if (avgSleepHours > 9.5) {
      insights.add('💤 평균 수면 시간이 많습니다. 과다수면도 피로의 원인이 될 수 있어요.');
    }

    // 수면 일관성 분석
    if (sleepConsistency > 0.8) {
      insights.add('🎯 수면 패턴이 매우 일관적입니다. 훌륭해요!');
    } else if (sleepConsistency < 0.5) {
      insights.add('📊 수면 시간이 불규칙합니다. 일정한 시간에 자고 일어나는 것이 중요해요.');
    }

    // 수면 품질 분석
    if (avgSleepScore >= 4.0) {
      insights.add('⭐ 수면 품질이 우수합니다!');
    } else if (avgSleepScore < 3.0) {
      insights.add('😴 수면 품질이 좋지 않습니다. 환경과 습관을 점검해보세요.');
    }

    // 낮 졸음 분석
    if (avgDaytimeSleepiness > 3.5) {
      insights.add('⚡ 낮 졸음이 심한 편입니다. 수면 부족이나 수면 무호흡증을 의심해볼 수 있어요.');
    } else if (avgDaytimeSleepiness < 2.0) {
      insights.add('😃 낮 동안 활기차게 생활하고 있습니다!');
    }

    return insights;
  }

  List<String> _generateRecommendations({
    required double avgSleepHours,
    required double sleepConsistency,
    required double avgSleepScore,
    required double avgDaytimeSleepiness,
    required Map<String, double> envCorrelation,
    required List<SleepFeedback> feedbacks,
    required AdaptiveParams adaptiveParams,
  }) {
    final recommendations = <String>[];

    // 수면 시간 기반 추천
    if (avgSleepHours < adaptiveParams.tSleep - 0.5) {
      recommendations.add('💤 취침 시간을 30분 앞당겨보세요.');
    }

    // 일관성 기반 추천
    if (sleepConsistency < 0.6) {
      recommendations.add('⏰ 매일 같은 시간에 자고 일어나는 습관을 들이세요. 주말에도 2시간 이상 차이나지 않도록 해보세요.');
    }

    // 카페인 영향 분석
    final cafImpact = envCorrelation['caffeineImpact'] ?? 0.0;
    if (cafImpact > 0.5) {
      recommendations.add('☕ 카페인이 수면에 큰 영향을 미치고 있습니다. 오후 ${(6 - adaptiveParams.cafWindow).toStringAsFixed(0)}시 이후 카페인 섭취를 피하세요.');
    }

    // 빛 노출 영향 분석
    final lightImpact = envCorrelation['lightImpact'] ?? 0.0;
    if (lightImpact > 0.5) {
      recommendations.add('💡 취침 전 밝은 빛 노출이 수면을 방해하고 있습니다. 취침 ${adaptiveParams.winddownMinutes}분 전부터 화면 밝기를 줄이고 조명을 어둡게 해보세요.');
    }

    // 환경 소음 분석
    final avgNoise = envCorrelation['avgNoise'] ?? 0.0;
    if (avgNoise > 45) {
      recommendations.add('🔇 평균 소음 수준이 높습니다 (${avgNoise.toStringAsFixed(1)}dB). 귀마개나 백색소음을 사용해보세요.');
    }

    // 환경 조도 분석
    final avgLux = envCorrelation['avgLux'] ?? 0.0;
    if (avgLux > 80) {
      recommendations.add('🌙 수면 환경이 너무 밝습니다 (${avgLux.toStringAsFixed(1)}lx). 암막커튼이나 수면안대를 사용해보세요.');
    }

    // 낮 졸음 기반 추천
    if (avgDaytimeSleepiness > 3.5) {
      recommendations.add('🏥 지속적인 낮 졸음은 수면 장애의 신호일 수 있습니다. 필요시 전문의 상담을 고려해보세요.');
    }

    // 기본 추천사항 (데이터 부족 시)
    if (recommendations.isEmpty) {
      recommendations.add('✨ 현재 수면 패턴을 잘 유지하고 있습니다. 계속 피드백을 입력하면 더 정확한 분석이 가능해요!');
    }

    return recommendations;
  }

  Map<String, dynamic> _generateTrendData(
      List<SleepEntry> entries, List<SleepFeedback> feedbacks) {
    
    // 날짜별 수면 시간
    final sleepHoursByDate = <DateTime, double>{};
    for (final entry in entries) {
      final key = entry.dateKey;
      sleepHoursByDate[key] = (sleepHoursByDate[key] ?? 0) +
          entry.duration.inMinutes / 60.0;
    }

    // 날짜별 수면 점수
    final sleepScoreByDate = <DateTime, double>{};
    for (final feedback in feedbacks) {
      sleepScoreByDate[feedback.dateKey] = feedback.sleepScore;
    }

    return {
      'sleepHoursByDate': sleepHoursByDate,
      'sleepScoreByDate': sleepScoreByDate,
    };
  }
}

