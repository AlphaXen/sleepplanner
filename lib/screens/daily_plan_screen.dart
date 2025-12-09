import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/settings_provider.dart';
import '../models/daily_plan.dart';
import '../models/shift_info.dart';
import '../utils/date_utils.dart';
import 'integrated_sleep_management_screen.dart';

class DailyPlanScreen extends StatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  bool _isLoading = false;
  DateTime? _lastScheduleWeekStart; // 스케줄의 weekStart만 추적
  bool _isUpdating = false;
  bool _hasInitialized = false; // 초기화 완료 플래그

  @override
  void initState() {
    super.initState();
    // 화면이 열릴 때 자동으로 최신 계획 계산 (한 번만)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _hasInitialized = true;
        _updateTodayPlan();
      }
    });
  }

  void _updateTodayPlan() {
    // 중복 호출 방지
    if (_isUpdating || _isLoading) {
      debugPrint('   ⏭️ _updateTodayPlan 중복 호출 방지');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _isUpdating = true;
    });

    final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    final now = DateTime.now();
    final today = getTodayKey(settingsProvider.dayStartHour);
    final schedule = scheduleProvider.currentSchedule;
    
    // 스케줄의 weekStart 추적 (객체 참조 대신 날짜만 비교)
    final currentScheduleWeekStart = schedule?.weekStart;
    final scheduleChanged = _lastScheduleWeekStart != currentScheduleWeekStart;
    
    debugPrint('📋 일일 수면 계획 화면 - 계획 생성 시작');
    debugPrint('   현재 시간: ${now.toString()}');
    debugPrint('   오늘 날짜 키: ${today.toString()}');
    debugPrint('   하루 시작 시간: ${settingsProvider.dayStartHour}시');
    debugPrint('   스케줄 변경 여부: $scheduleChanged');
    debugPrint('   이전 스케줄 주: ${_lastScheduleWeekStart?.toString() ?? "null"}');
    debugPrint('   현재 스케줄 주: ${currentScheduleWeekStart?.toString() ?? "null"}');
    
    if (schedule != null) {
      debugPrint('   주간 스케줄 존재: ${schedule.weekStart.toString()}');
      
      // 주간 스케줄이 현재 주인지 확인
      final scheduleWeekStart = schedule.weekStart;
      
      // 같은 주인지 확인 (일주일 내)
      final daysDiff = today.difference(scheduleWeekStart).inDays;
      final isSameWeek = daysDiff >= 0 && daysDiff < 7;
      
      debugPrint('   스케줄 주 시작: ${scheduleWeekStart.toString()}');
      debugPrint('   주 차이: $daysDiff일 (같은 주: $isSameWeek)');
      
      ShiftInfo? todayShift;
      if (isSameWeek) {
        todayShift = schedule.getShiftForDate(today);
      } else {
        // 다른 주면 요일만 매칭 (임시 조치)
        final dayOfWeek = today.weekday - 1;
        todayShift = schedule.shifts[dayOfWeek];
        debugPrint('   ⚠️ 다른 주 스케줄 - 요일만 매칭 (요일: $dayOfWeek)');
      }
      
      if (todayShift != null) {
        debugPrint('   오늘 근무 유형: ${todayShift.type}');
        
        sleepProvider.computeTodayPlanForShift(
          shift: todayShift,
          weeklySchedule: schedule,
          dayStartHour: settingsProvider.dayStartHour,
        );
        
        final plan = sleepProvider.lastDailyPlan;
        if (plan != null) {
          debugPrint('   ✅ 계획 생성 완료');
        } else {
          debugPrint('   ⚠️ 계획 생성 실패 - 근무 시간대일 수 있음');
        }
      } else {
        debugPrint('   ⚠️ 오늘 근무 정보 없음 - 주간 스케줄만 전달');
        sleepProvider.computeTodayPlanForShift(
          shift: null,
          weeklySchedule: schedule,
          dayStartHour: settingsProvider.dayStartHour,
        );
      }
      
      // 스케줄 weekStart 업데이트
      _lastScheduleWeekStart = currentScheduleWeekStart;
    } else {
      debugPrint('   ⚠️ 주간 스케줄 없음 - 기본 휴무로 처리');
      // 스케줄이 아예 없으면 기본 휴무로 처리
      final defaultOff = ShiftInfo.off(preferredMid: DateTime(now.year, now.month, now.day, 3, 0));
      sleepProvider.computeTodayPlanForShift(
        shift: defaultOff,
        weeklySchedule: null,
        dayStartHour: settingsProvider.dayStartHour,
      );
      
      _lastScheduleWeekStart = null;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isUpdating = false;
      });
    }
  }

  String _fmt(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("일일 수면 계획"),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: _isLoading ? null : () {
              _updateTodayPlan();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('일일 수면 계획을 새로고침했습니다'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer3<SleepProvider, ScheduleProvider, SettingsProvider>(
        builder: (context, provider, scheduleProvider, settingsProvider, _) {
          final plan = provider.lastDailyPlan;
          final currentSchedule = scheduleProvider.currentSchedule;
          
          // 스케줄의 weekStart가 변경되었을 때만 자동으로 계획 재계산 (중복 방지)
          final currentScheduleWeekStart = currentSchedule?.weekStart;
          final scheduleChanged = _lastScheduleWeekStart != currentScheduleWeekStart;
          
          if (scheduleChanged && !_isUpdating && !_isLoading && _hasInitialized) {
            // 스케줄이 변경되었고, 업데이트 중이 아니고, 초기화가 완료된 경우에만 업데이트
            _lastScheduleWeekStart = currentScheduleWeekStart;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isUpdating) {
                _updateTodayPlan();
              }
            });
          }

          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (plan == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bedtime_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "일일 수면 계획이 없습니다",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "근무 정보를 입력하거나 수면 기록을 추가하면\n맞춤형 수면 계획이 자동으로 생성됩니다.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IntegratedSleepManagementScreen(),
                          ),
                        ).then((_) {
                          // 돌아왔을 때 계획 다시 계산
                          _updateTodayPlan();
                        });
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text('근무 정보 입력하러 가기'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        _updateTodayPlan();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('계획 다시 계산하기'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMainSleepCard(plan),
                const SizedBox(height: 16),
                _buildCaffeineCard(plan),
                const SizedBox(height: 16),
                _buildWinddownCard(plan),
                const SizedBox(height: 16),
                _buildLightCard(plan),
                const SizedBox(height: 16),
                _buildNotesCard(plan),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainSleepCard(DailyPlan plan) {
    final dur = plan.mainSleepEnd.difference(plan.mainSleepStart);
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);

    return Card(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "🛌 메인 수면 시간",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("시작: ${_fmt(plan.mainSleepStart)}"),
            const SizedBox(height: 8),
            Text("종료: ${_fmt(plan.mainSleepEnd)}"),
            const SizedBox(height: 8),
            Text("기간: ${h}시간 ${m}분"),
          ],
        ),
      ),
    );
  }

  Widget _buildCaffeineCard(DailyPlan plan) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "☕ 카페인 컷오프",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("카페인 제한 시작 시간: ${_fmt(plan.caffeineCutoff)}"),
            const SizedBox(height: 24), // 고정 높이로 통일
          ],
        ),
      ),
    );
  }

  Widget _buildWinddownCard(DailyPlan plan) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "🌙 취침 준비 시작 시간",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("취침 준비 시작: ${_fmt(plan.winddownStart)}"),
            const SizedBox(height: 24), // 고정 높이로 통일
          ],
        ),
      ),
    );
  }

  Widget _buildLightCard(DailyPlan plan) {
    final lightPlan = plan.lightPlan;
    final strategy = lightPlan['strategy']?.toString() ?? '';
    
    // 전략에 따른 설명 텍스트
    String strategyTitle;
    String strategyDescription;
    List<String> recommendations = [];
    
    switch (strategy) {
      case 'night_shift':
        strategyTitle = '야간 근무 빛 관리';
        strategyDescription = '야간 근무자를 위한 빛 노출 전략';
        if (lightPlan['work_bright_light'] == true) {
          recommendations.add('☀️ 근무 중 밝은 빛 노출 유지 (각성 유지)');
        }
        if (lightPlan['post_shift_block_light'] == true) {
          recommendations.add('🌙 근무 후 밝은 빛 차단 (수면 준비)');
        }
        break;
      case 'day_shift':
        strategyTitle = '주간 근무 빛 관리';
        strategyDescription = '주간 근무자를 위한 빛 노출 전략';
        if (lightPlan['morning_bright_light'] == true) {
          recommendations.add('☀️ 아침에 밝은 빛 노출 (수면-각성 리듬 조절)');
        }
        if (lightPlan['evening_dim_light'] == true) {
          recommendations.add('🌙 저녁에 빛 줄이기 (수면 준비)');
        }
        break;
      case 'off_day':
        strategyTitle = '휴무일 빛 관리';
        strategyDescription = '휴무일을 위한 빛 노출 전략';
        if (lightPlan['align_with_preferred_mid'] == true) {
          recommendations.add('🌅 선호하는 수면 패턴에 맞춘 빛 노출');
        }
        recommendations.add('☀️ 자연스러운 낮/밤 주기 유지');
        break;
      default:
        strategyTitle = '빛 노출 전략';
        strategyDescription = '맞춤형 빛 관리';
    }
    
    final lightSensitivity = lightPlan['light_sensitivity'];
    final sensitivityText = lightSensitivity is num 
        ? '빛 민감도: ${lightSensitivity.toStringAsFixed(2)}' 
        : '';

    return Card(
      color: Colors.yellow.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.light_mode, size: 24, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strategyTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (strategyDescription.isNotEmpty)
                        Text(
                          strategyDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sensitivityText.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      sensitivityText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            rec,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(DailyPlan plan) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "📝 메모",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...plan.notes.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(n),
                )),
            if (plan.notes.length <= 2) const SizedBox(height: 24), // 내용이 적을 경우 고정 높이
          ],
        ),
      ),
    );
  }
}
