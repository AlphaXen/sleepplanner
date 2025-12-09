import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sleep_entry.dart';
import '../services/notification_service.dart';
import '../models/adaptive_params.dart';
import '../models/shift_info.dart';
import '../models/daily_plan.dart';
import '../services/adaptive_sleep_service.dart';
import '../services/alarm_service.dart';

void scheduleSleepAlarm(DateTime wakeTime) {
  AlarmService.instance.scheduleAlarm(wakeTime);
}

class SleepProvider extends ChangeNotifier {
  final List<SleepEntry> _entries = [];
  int _dailyTargetHours = 7;
  bool _goalNotifiedToday = false;

  // Adaptive system 관련 상태
  AdaptiveParams adaptiveParams = AdaptiveParams();
  final AdaptiveSleepService _adaptiveService = AdaptiveSleepService();
  DailyPlan? lastDailyPlan;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  List<SleepEntry> get entries => List.unmodifiable(_entries);
  int get dailyTargetHours => _dailyTargetHours;

  /// 사용자 설정 및 Firestore 동기화 시작
  void setUser(User? user) {
    _currentUser = user;
    if (user != null) {
      _loadFromFirestore();
    }
  }

  void setDailyTarget(int hours) {
    if (hours <= 0) return;
    _dailyTargetHours = hours;
    _resetGoalFlagIfNewDay();
    _checkGoalAndNotify();
    notifyListeners();
  }

  Future<void> addEntry(SleepEntry entry) async {
    _entries.add(entry);
    _resetGoalFlagIfNewDay();
    _checkGoalAndNotify();
    
    // Firestore에 저장 (로그인 상태일 때만)
    if (_currentUser != null) {
      await _saveToFirestore(entry);
    }
    
    notifyListeners();
  }

  /// Firestore에서 데이터 로드
  Future<void> _loadFromFirestore() async {
    if (_currentUser == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('sleep_entries')
          .orderBy('wakeTime', descending: true)
          .get();

      _entries.clear();
      for (final doc in snapshot.docs) {
        _entries.add(SleepEntry.fromJson(doc.id, doc.data()));
      }

      debugPrint('Loaded ${_entries.length} sleep entries from Firestore');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from Firestore: $e');
    }
  }

  /// Firestore에 데이터 저장
  Future<void> _saveToFirestore(SleepEntry entry) async {
    if (_currentUser == null) return;

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('sleep_entries')
          .add(entry.toJson());

      debugPrint('Saved sleep entry to Firestore: ${docRef.id}');
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
      // 저장 실패해도 로컬에는 저장되어 있으므로 계속 진행
    }
  }

  /// 수동으로 Firestore 동기화
  Future<void> syncWithFirestore() async {
    if (_currentUser != null) {
      await _loadFromFirestore();
    }
  }

  Duration get todaySleepDuration {
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    Duration total = Duration.zero;
    for (final e in _entries) {
      if (e.dateKey == todayKey) {
        total += e.duration;
      }
    }
    return total;
  }

  double get todayProgress {
    final targetMinutes = _dailyTargetHours * 60;
    final sleptMinutes = todaySleepDuration.inMinutes;
    if (targetMinutes <= 0) return 0;
    return (sleptMinutes / targetMinutes).clamp(0, 1);
  }

  /// 최근 7일 수면시간 (시간 단위)
  Map<DateTime, double> get last7DaysSleepHours {
    final now = DateTime.now();
    final Map<DateTime, double> result = {};
    for (int i = 6; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      result[day] = 0;
    }
    for (final e in _entries) {
      final key = e.dateKey;
      if (result.containsKey(key)) {
        result[key] = (result[key] ?? 0) + e.duration.inMinutes / 60.0;
      }
    }
    return result;
  }

  void _resetGoalFlagIfNewDay() {
    _goalNotifiedToday = todayProgress >= 1 ? _goalNotifiedToday : false;
  }

  Future<void> _checkGoalAndNotify() async {
    if (!_goalNotifiedToday && todayProgress >= 1) {
      _goalNotifiedToday = true;
      await NotificationService.instance.showGoalReachedNotification();
    }
  }

  /// Adaptive 알고리즘: 오늘 근무 정보를 기반으로 DailyPlan 계산
  void computeTodayPlanForShift(ShiftInfo shift) {
    lastDailyPlan = _adaptiveService.computeDailyPlan(
      params: adaptiveParams,
      shift: shift,
    );
    notifyListeners();
  }

  /// 주 단위 적응 알고리즘 helper
  void adaptWeeklyWithSummary({
    required double avgActualSleep,
    required double avgSleepScore,
    required double avgDaytimeSleepiness,
    required double meanScoreNoLateCaf,
    required double meanScoreLateCaf,
    required double meanScoreLowLight,
    required double meanScoreHighLight,
    required DateTime? preferredMidOffDays,
  }) {
    // 기준 mid0: 새벽 3시
    final mid0 = DateTime(2000, 1, 1, 3, 0);

    adaptiveParams = _adaptiveService.adaptWeekly(
      current: adaptiveParams,
      avgActualSleep: avgActualSleep,
      avgSleepScore: avgSleepScore,
      avgDaytimeSleepiness: avgDaytimeSleepiness,
      meanScoreNoLateCaf: meanScoreNoLateCaf,
      meanScoreLateCaf: meanScoreLateCaf,
      meanScoreLowLight: meanScoreLowLight,
      meanScoreHighLight: meanScoreHighLight,
      preferredMidOffDays: preferredMidOffDays,
      mid0: mid0,
    );

    notifyListeners();
  }
}
