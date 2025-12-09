import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sleep_feedback.dart';

class FeedbackProvider extends ChangeNotifier {
  final List<SleepFeedback> _feedbacks = [];

  List<SleepFeedback> get feedbacks => List.unmodifiable(_feedbacks);

  FeedbackProvider() {
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('sleep_feedbacks');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _feedbacks.clear();
        _feedbacks.addAll(
          list.map((e) => SleepFeedback.fromJson(e)).toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading feedbacks: $e');
    }
  }

  Future<void> _saveFeedbacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _feedbacks.map((e) => e.toJson()).toList();
      await prefs.setString('sleep_feedbacks', jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving feedbacks: $e');
    }
  }

  void addFeedback(SleepFeedback feedback) {
    // 같은 날짜의 피드백이 있으면 제거
    _feedbacks.removeWhere((f) => f.dateKey == feedback.dateKey);
    _feedbacks.add(feedback);
    _saveFeedbacks();
    notifyListeners();
  }

  SleepFeedback? getFeedbackForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    try {
      return _feedbacks.firstWhere((f) => f.dateKey == key);
    } catch (e) {
      return null;
    }
  }

  /// 최근 N일간의 피드백 가져오기
  List<SleepFeedback> getRecentFeedbacks(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _feedbacks
        .where((f) => f.date.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// 주간 평균 계산 (최근 7일)
  Map<String, double> getWeeklyAverages() {
    final recent = getRecentFeedbacks(7);
    if (recent.isEmpty) {
      return {
        'avgSleepScore': 3.0,
        'avgDaytimeSleepiness': 3.0,
        'meanScoreNoLateCaf': 3.0,
        'meanScoreLateCaf': 3.0,
        'meanScoreLowLight': 3.0,
        'meanScoreHighLight': 3.0,
      };
    }

    double totalScore = 0;
    double totalSleepiness = 0;
    
    final noCafScores = <double>[];
    final lateCafScores = <double>[];
    final lowLightScores = <double>[];
    final highLightScores = <double>[];

    for (final f in recent) {
      totalScore += f.sleepScore;
      totalSleepiness += f.daytimeSleepiness;

      if (f.hadLateCaffeine) {
        lateCafScores.add(f.sleepScore);
      } else {
        noCafScores.add(f.sleepScore);
      }

      if (f.hadHighLightExposure) {
        highLightScores.add(f.sleepScore);
      } else {
        lowLightScores.add(f.sleepScore);
      }
    }

    return {
      'avgSleepScore': totalScore / recent.length,
      'avgDaytimeSleepiness': totalSleepiness / recent.length,
      'meanScoreNoLateCaf': noCafScores.isEmpty 
          ? 3.0 
          : noCafScores.reduce((a, b) => a + b) / noCafScores.length,
      'meanScoreLateCaf': lateCafScores.isEmpty 
          ? 3.0 
          : lateCafScores.reduce((a, b) => a + b) / lateCafScores.length,
      'meanScoreLowLight': lowLightScores.isEmpty 
          ? 3.0 
          : lowLightScores.reduce((a, b) => a + b) / lowLightScores.length,
      'meanScoreHighLight': highLightScores.isEmpty 
          ? 3.0 
          : highLightScores.reduce((a, b) => a + b) / highLightScores.length,
    };
  }
}

