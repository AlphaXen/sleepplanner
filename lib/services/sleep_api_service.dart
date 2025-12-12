import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SleepApiService {
  static final SleepApiService instance = SleepApiService._internal();
  factory SleepApiService() => instance;
  SleepApiService._internal();

  static const platform = MethodChannel('com.example.sleep_tracker/sleep');
  static const String _nativeKey = 'native_pending_sleep_data';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> requestSleepUpdates() async {
    try {
      final result = await platform.invokeMethod('requestSleepUpdates');
      debugPrint('Sleep API 구독 결과: $result');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Sleep API 구독 실패: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Sleep API 구독 실패 (일반 오류): $e');
      debugPrint('오류 타입: ${e.runtimeType}');
      return false;
    }
  }

  Future<Map<String, DateTime>?> getLatestSleepData() async {
    if (_prefs == null) await init();

    // Kotlin에서 직접 SharedPreferences에 저장할 때는 "flutter." 프리픽스가 없음
    const key = _nativeKey; // 'native_pending_sleep_data'
    debugPrint('🔍 Sleep API 데이터 읽기 시도 - 키: $key');
    
    // 모든 키 확인 (디버그용)
    final allKeys = _prefs?.getKeys();
    debugPrint('📋 SharedPreferences 모든 키: $allKeys');
    
    final String? nativeJson = _prefs?.getString(key);
    debugPrint('📦 읽은 데이터: ${nativeJson != null ? "${nativeJson.length} bytes" : "null"}');
    
    if (nativeJson == null || nativeJson == "[]") {
      debugPrint('⚠️ 저장된 Sleep API 데이터가 없습니다.');
      debugPrint('   키 "$key"로 저장된 데이터가 없거나 비어있습니다.');
      return null;
    }
    
    debugPrint('✅ 데이터 발견: ${nativeJson.substring(0, nativeJson.length > 200 ? 200 : nativeJson.length)}...');

    try {
      final List<dynamic> nativeList = jsonDecode(nativeJson);
      if (nativeList.isEmpty) return null;

      // 가장 최근 데이터 가져오기
      final latestData = nativeList.last;
      
      // ISO8601 형식 문자열 파싱 (타임존 정보 포함)
      final sleepTimeStr = latestData['sleepTime'] as String;
      final wakeTimeStr = latestData['wakeTime'] as String;
      
      debugPrint('📅 원본 문자열 - sleepTime: $sleepTimeStr, wakeTime: $wakeTimeStr');
      
      final sleepTime = DateTime.parse(sleepTimeStr);
      final wakeTime = DateTime.parse(wakeTimeStr);
      
      debugPrint('📅 파싱된 시간 - sleepTime: ${sleepTime.toString()}, wakeTime: ${wakeTime.toString()}');
      debugPrint('📅 수면 시간: ${sleepTime.year}-${sleepTime.month}-${sleepTime.day} ${sleepTime.hour}:${sleepTime.minute}');
      debugPrint('📅 기상 시간: ${wakeTime.year}-${wakeTime.month}-${wakeTime.day} ${wakeTime.hour}:${wakeTime.minute}');
      
      // 비정상적인 수면 시간 검증 (24시간 이상이거나 음수인 경우)
      final duration = wakeTime.difference(sleepTime);
      if (duration.inHours > 24 || duration.isNegative) {
        debugPrint('⚠️ 비정상적인 수면 시간 감지: ${duration.inHours}시간 ${duration.inMinutes.remainder(60)}분');
        debugPrint('   원본 데이터가 잘못되었을 수 있습니다.');
        return null;
      }

      return {
        'sleepTime': sleepTime,
        'wakeTime': wakeTime,
      };
    } catch (e) {
      debugPrint('Sleep API 데이터 파싱 오류: $e');
      debugPrint('   스택 트레이스: ${StackTrace.current}');
      return null;
    }
  }

  Map<String, DateTime> getDefaultEstimate() {
    final now = DateTime.now();
    
    // 현재 시간에 따라 적절한 기본값 설정
    DateTime estimatedSleep;
    DateTime estimatedWake;
    
    if (now.hour >= 0 && now.hour < 12) {
      // 오전이면 오늘 새벽 ~ 오늘 아침 (같은 날)
      estimatedSleep = DateTime(now.year, now.month, now.day, 2, 30);
      estimatedWake = DateTime(now.year, now.month, now.day, 7, 0);
    } else {
      // 오후/저녁이면 내일 새벽 ~ 내일 아침 (같은 날)
      final tomorrow = now.add(const Duration(days: 1));
      estimatedSleep = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 2, 30);
      estimatedWake = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 7, 0);
    }

    return {
      'sleepTime': estimatedSleep,
      'wakeTime': estimatedWake,
    };
  }

  Future<void> clearNativeData() async {
    if (_prefs == null) await init();
    await _prefs?.remove(_nativeKey); // 프리픽스 없이
  }
}

