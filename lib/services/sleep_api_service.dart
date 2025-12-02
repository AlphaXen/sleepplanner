import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Google Sleep API를 통해 수면 데이터를 가져오는 서비스
class SleepApiService {
  static final SleepApiService instance = SleepApiService._internal();
  factory SleepApiService() => instance;
  SleepApiService._internal();

  static const platform = MethodChannel('com.example.sleep_tracker/sleep');
  static const String _nativeKey = 'native_pending_sleep_data'; // Kotlin이 저장하는 키

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Sleep API 구독 시작 요청
  Future<bool> requestSleepUpdates() async {
    try {
      final result = await platform.invokeMethod('requestSleepUpdates');
      return result == true;
    } catch (e) {
      debugPrint('Sleep API 구독 실패: $e');
      return false;
    }
  }

  /// 네이티브에서 저장한 최신 수면 데이터 가져오기
  Future<Map<String, DateTime>?> getLatestSleepData() async {
    if (_prefs == null) await init();

    final String? nativeJson = _prefs?.getString('flutter.$_nativeKey');
    if (nativeJson == null || nativeJson == "[]") {
      debugPrint('저장된 Sleep API 데이터가 없습니다.');
      return null;
    }

    try {
      final List<dynamic> nativeList = jsonDecode(nativeJson);
      if (nativeList.isEmpty) return null;

      // 가장 최근 데이터 가져오기
      final latestData = nativeList.last;
      final sleepTime = DateTime.parse(latestData['sleepTime']);
      final wakeTime = DateTime.parse(latestData['wakeTime']);

      return {
        'sleepTime': sleepTime,
        'wakeTime': wakeTime,
      };
    } catch (e) {
      debugPrint('Sleep API 데이터 파싱 오류: $e');
      return null;
    }
  }

  /// 기본 추정값 생성 (API 데이터가 없을 때)
  Map<String, DateTime> getDefaultEstimate() {
    final now = DateTime.now();
    
    // 현재 시간에 따라 적절한 기본값 설정
    DateTime estimatedSleep;
    DateTime estimatedWake;
    
    if (now.hour >= 0 && now.hour < 12) {
      // 오전이면 어제 밤 ~ 오늘 아침
      estimatedSleep = DateTime(now.year, now.month, now.day - 1, 23, 0);
      estimatedWake = DateTime(now.year, now.month, now.day, 7, 30);
    } else {
      // 오후/저녁이면 오늘 밤 ~ 내일 아침
      estimatedSleep = DateTime(now.year, now.month, now.day, 23, 0);
      estimatedWake = DateTime(now.year, now.month, now.day + 1, 7, 30);
    }

    return {
      'sleepTime': estimatedSleep,
      'wakeTime': estimatedWake,
    };
  }

  /// 네이티브 임시 데이터 삭제
  Future<void> clearNativeData() async {
    if (_prefs == null) await init();
    await _prefs?.remove('flutter.$_nativeKey');
  }
}

