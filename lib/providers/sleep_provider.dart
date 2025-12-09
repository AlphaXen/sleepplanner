import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sleep_entry.dart';
import '../services/notification_service.dart';
import '../models/adaptive_params.dart';
import '../models/shift_info.dart';
import '../models/daily_plan.dart';
import '../models/weekly_schedule.dart';
import '../services/adaptive_sleep_service.dart';
import '../services/alarm_service.dart';
import '../utils/date_utils.dart';

void scheduleSleepAlarm(DateTime wakeTime) {
  AlarmService.instance.scheduleAlarm(wakeTime);
}

class SleepProvider extends ChangeNotifier {
  final List<SleepEntry> _entries = [];
  int _dailyTargetHours = 7; // 기본값 (SettingsProvider와 동기화됨)
  bool _goalNotifiedToday = false;

  // Adaptive system 관련 상태
  AdaptiveParams adaptiveParams = AdaptiveParams();
  final AdaptiveSleepService _adaptiveService = AdaptiveSleepService();
  DailyPlan? lastDailyPlan;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  /// 수면 기록 목록 (기상 시간 기준 내림차순 정렬 - 최신 기록이 위에)
  List<SleepEntry> get entries {
    final sorted = List<SleepEntry>.from(_entries);
    sorted.sort((a, b) => b.wakeTime.compareTo(a.wakeTime));
    return List.unmodifiable(sorted);
  }
  
  // 하위 호환성을 위한 getter (기본값 7)
  int get dailyTargetHours => _dailyTargetHours;

  /// 사용자 설정 및 Firestore 동기화 시작
  void setUser(User? user) {
    _currentUser = user;
    if (user != null) {
      _loadFromFirestore();
    }
  }

  void setDailyTarget(int hours) {
    // SettingsProvider에서 관리하므로 여기서는 알림만
    _resetGoalFlagIfNewDay();
    _checkGoalAndNotify();
    notifyListeners();
  }

  Future<void> addEntry(SleepEntry entry) async {
    // Firestore에 저장 후 ID가 업데이트된 entry 사용
    SleepEntry entryToAdd = entry;
    if (_currentUser != null) {
      entryToAdd = await _saveToFirestore(entry);
    }
    
    _entries.add(entryToAdd);
    _resetGoalFlagIfNewDay();
    _checkGoalAndNotify();
    notifyListeners();
  }

  /// 수면 기록 삭제
  Future<void> deleteEntry(SleepEntry entry) async {
    // 로컬에서 삭제
    _entries.removeWhere((e) => e.id == entry.id || (e.id == null && e.sleepTime == entry.sleepTime && e.wakeTime == entry.wakeTime));
    _resetGoalFlagIfNewDay();
    _checkGoalAndNotify();
    
    // Firestore에서 삭제 (로그인 상태이고 ID가 있을 때만)
    if (_currentUser != null && entry.id != null && entry.id!.isNotEmpty) {
      try {
        await _deleteFromFirestore(entry.id!);
      } catch (e) {
        debugPrint('Firestore 삭제 실패: $e');
        // 삭제 실패 시 로컬은 이미 삭제되었으므로 계속 진행
      }
    }
    
    notifyListeners();
  }

  /// 수면 기록 수정
  Future<void> updateEntry(SleepEntry oldEntry, SleepEntry newEntry) async {
    // 로컬에서 업데이트
    final index = _entries.indexWhere((e) => 
      (oldEntry.id != null && e.id == oldEntry.id) || 
      (oldEntry.id == null && e.sleepTime == oldEntry.sleepTime && e.wakeTime == oldEntry.wakeTime)
    );
    if (index != -1) {
      // ID는 유지하고 Firestore에 저장
      SleepEntry updatedEntry = newEntry.copyWith(id: oldEntry.id);
      if (_currentUser != null) {
        updatedEntry = await _saveToFirestore(updatedEntry);
      }
      
      _entries[index] = updatedEntry;
      _resetGoalFlagIfNewDay();
      _checkGoalAndNotify();
      notifyListeners();
    }
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
  /// 반환값: 저장된 entry (ID가 업데이트된 경우)
  Future<SleepEntry> _saveToFirestore(SleepEntry entry) async {
    if (_currentUser == null) return entry;

    try {
      if (entry.id != null && entry.id!.isNotEmpty) {
        // 기존 문서 업데이트
        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('sleep_entries')
            .doc(entry.id)
            .update(entry.toJson());
        debugPrint('Updated sleep entry in Firestore: ${entry.id}');
        return entry;
      } else {
        // 새 문서 추가
        final docRef = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('sleep_entries')
            .add(entry.toJson());
        debugPrint('Saved sleep entry to Firestore: ${docRef.id}');
        // ID가 업데이트된 entry 반환
        return entry.copyWith(id: docRef.id);
      }
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
      // 저장 실패해도 로컬에는 저장되어 있으므로 계속 진행
      return entry;
    }
  }

  /// Firestore에서 데이터 삭제
  Future<void> _deleteFromFirestore(String entryId) async {
    if (_currentUser == null || entryId.isEmpty) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('sleep_entries')
          .doc(entryId)
          .delete();
      debugPrint('Deleted sleep entry from Firestore: $entryId');
    } catch (e) {
      debugPrint('Error deleting from Firestore: $e');
      rethrow;
    }
  }

  /// 수동으로 Firestore 동기화
  Future<void> syncWithFirestore() async {
    if (_currentUser != null) {
      await _loadFromFirestore();
    }
  }

  Duration getTodaySleepDuration(int dayStartHour) {
    final todayKey = getTodayKey(dayStartHour);
    Duration total = Duration.zero;
    for (final e in _entries) {
      final entryDateKey = getDateKey(e.wakeTime, dayStartHour);
      if (entryDateKey == todayKey) {
        total += e.duration;
      }
    }
    return total;
  }

  double getTodayProgress(int dayStartHour, int targetHours) {
    final targetMinutes = targetHours * 60;
    final sleptMinutes = getTodaySleepDuration(dayStartHour).inMinutes;
    if (targetMinutes <= 0) return 0;
    return (sleptMinutes / targetMinutes).clamp(0, 1);
  }
  
  // 기존 호환성을 위한 getter (dayStartHour=0 사용)
  Duration get todaySleepDuration {
    return getTodaySleepDuration(0);
  }

  double get todayProgress {
    return getTodayProgress(0, _dailyTargetHours);
  }

  /// 최근 7일 수면시간 (시간 단위)
  Map<DateTime, double> getLast7DaysSleepHours(int dayStartHour) {
    final todayKey = getTodayKey(dayStartHour);
    final Map<DateTime, double> result = {};
    for (int i = 6; i >= 0; i--) {
      final day = todayKey.subtract(Duration(days: i));
      result[day] = 0;
    }
    for (final e in _entries) {
      final key = getDateKey(e.wakeTime, dayStartHour);
      if (result.containsKey(key)) {
        result[key] = (result[key] ?? 0) + e.duration.inMinutes / 60.0;
      }
    }
    return result;
  }
  
  // 기존 호환성을 위한 getter
  Map<DateTime, double> get last7DaysSleepHours {
    return getLast7DaysSleepHours(0);
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
  /// 주간 스케줄과 dayStartHour를 받아서 전달
  void computeTodayPlanForShift({
    ShiftInfo? shift,
    WeeklySchedule? weeklySchedule,
    int dayStartHour = 0,
  }) {
    final newPlan = _adaptiveService.computeDailyPlan(
      params: adaptiveParams,
      shift: shift,
      weeklySchedule: weeklySchedule,
      dayStartHour: dayStartHour,
    );
    
    // newPlan이 null이면 이전 계획 유지 (변경 없음)
    if (newPlan == null) {
      return;
    }
    
    // 실제로 계획이 변경되었을 때만 notifyListeners 호출 (무한 루프 방지)
    final oldPlan = lastDailyPlan;
    bool hasChanged;
    if (oldPlan == null) {
      hasChanged = true;
    } else {
      hasChanged = oldPlan.mainSleepStart != newPlan.mainSleepStart ||
          oldPlan.mainSleepEnd != newPlan.mainSleepEnd ||
          oldPlan.caffeineCutoff != newPlan.caffeineCutoff;
    }
    
    if (hasChanged) {
      lastDailyPlan = newPlan;
      notifyListeners();
    } else {
      // 내용이 같더라도 참조 업데이트
      lastDailyPlan = newPlan;
    }
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
