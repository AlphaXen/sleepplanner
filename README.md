# SleepPlanner Full Adaptive (v2)

교대·야간 근무자를 위한 Sleep Planner 앱 예제입니다.

## 포함 기능

- 수면 기록 관리
- Daily Target 설정
- 목표 달성 시 로컬 Notification
- 최근 7일 수면 그래프 (Line chart, fl_chart)
- 오늘 목표 달성률 Pie chart
- Adaptive Sleep Algorithm
  - AdaptiveParams (T_sleep, caf_window, winddown, chrono_offset, light_sens, caf_sens)
  - DAILY Recommendation (근무 타입/시간에 따른 수면 계획)
  - Weekly Adaptation (adaptWeekly + SleepProvider.adaptWeeklyWithSummary)
- Daily Sleep Plan UI
  - Main sleep
  - Caffeine cutoff
  - Wind-down start
  - Light plan
  - Notes

## 실행 방법

```bash
flutter pub get
flutter create .
flutter run
```

> android/ios 폴더가 없다면 `flutter create .` 명령으로 생성해 주세요.

## 주요 파일 구조

```text
lib/
 ├─ main.dart
 ├─ models/
 │   ├─ sleep_entry.dart
 │   ├─ adaptive_params.dart
 │   ├─ shift_info.dart
 │   └─ daily_plan.dart
 ├─ providers/
 │   └─ sleep_provider.dart
 ├─ services/
 │   ├─ notification_service.dart
 │   └─ adaptive_sleep_service.dart
 └─ screens/
     ├─ home_screen.dart
     ├─ stats_screen.dart
     ├─ daily_plan_screen.dart
     └─ shift_input_screen.dart
```
