import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyDailyTargetHours = 'daily_target_hours';
  static const String _keyDayStartHour = 'day_start_hour';
  
  int _dailyTargetHours = 7;
  int _dayStartHour = 0; // 기본값: 자정 (0시)

  int get dailyTargetHours => _dailyTargetHours;
  int get dayStartHour => _dayStartHour;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyTargetHours = prefs.getInt(_keyDailyTargetHours) ?? 7;
    _dayStartHour = prefs.getInt(_keyDayStartHour) ?? 0;
    notifyListeners();
  }

  Future<void> setDailyTargetHours(int hours) async {
    if (hours <= 0 || hours > 24) return;
    _dailyTargetHours = hours;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyTargetHours, hours);
    notifyListeners();
  }

  Future<void> setDayStartHour(int hour) async {
    if (hour < 0 || hour >= 24) return;
    _dayStartHour = hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDayStartHour, hour);
    notifyListeners();
  }
}

