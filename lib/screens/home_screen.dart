import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/sleep_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/settings_provider.dart';
import '../models/shift_info.dart';
import '../utils/date_utils.dart';
import 'settings_screen.dart';
import 'daily_plan_screen.dart';
import '../models/sleep_entry.dart';
import '../widgets/daily_tip_card.dart';
import '../services/sleep_api_service.dart';
import 'auto_reply_settings_screen.dart';
import 'alarm_screen.dart';
import 'sleep_music_screen.dart';
import 'calendar_screen.dart';
import 'daily_suggestions_screen.dart';
import 'environment_checker_screen.dart';
import 'light_control_screen.dart';
import 'integrated_sleep_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 사용자 정보를 SleepProvider에 전달하고 스케줄 자동 생성
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      
      sleepProvider.setUser(authProvider.user);
      
      // Firebase에서 데이터 로드
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        await sleepProvider.syncWithFirestore();
        
        // ScheduleProvider의 스케줄 로드가 완료될 때까지 대기
        await scheduleProvider.waitForLoad();
        
        // 스케줄이 없을 때만 수면 기록으로부터 자동 생성
        // (기존 스케줄이 있으면 사용자가 설정한 것이므로 덮어쓰지 않음)
        if (sleepProvider.entries.isNotEmpty && scheduleProvider.currentSchedule == null) {
          await scheduleProvider.generateScheduleFromSleepEntries(
            sleepProvider.entries,
            dayStartHour: settingsProvider.dayStartHour,
            force: false, // 기존 스케줄이 있으면 덮어쓰지 않음
          );
        }
      }
      
      // 오늘의 적응형 수면 계획 자동 생성
      _updateTodayPlan(sleepProvider, scheduleProvider, settingsProvider);
    });
  }
  
  /// 오늘의 적응형 수면 계획 업데이트
  void _updateTodayPlan(SleepProvider sleepProvider, ScheduleProvider scheduleProvider, SettingsProvider settingsProvider) {
    final now = DateTime.now();
    final today = getTodayKey(settingsProvider.dayStartHour);
    final schedule = scheduleProvider.currentSchedule;
    
    debugPrint('🕐 적응형 수면 계획 생성 시작');
    debugPrint('   현재 시간: ${now.toString()}');
    debugPrint('   오늘 날짜 키: ${today.toString()}');
    debugPrint('   하루 시작 시간: ${settingsProvider.dayStartHour}시');
    
    if (schedule != null) {
      debugPrint('   주간 스케줄 존재: ${schedule.weekStart.toString()}');
      
      // 주간 스케줄이 현재 주인지 확인
      final scheduleWeekStart = schedule.weekStart;
      final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
      
      // 같은 주인지 확인 (일주일 내)
      final daysDiff = today.difference(scheduleWeekStart).inDays;
      final isSameWeek = daysDiff >= 0 && daysDiff < 7;
      
      debugPrint('   스케줄 주 시작: ${scheduleWeekStart.toString()}');
      debugPrint('   현재 주 시작: ${currentWeekStart.toString()}');
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
        if (todayShift.shiftStart != null) {
          debugPrint('   근무 시작: ${todayShift.shiftStart.toString()}');
        }
        if (todayShift.shiftEnd != null) {
          debugPrint('   근무 종료: ${todayShift.shiftEnd.toString()}');
        }
        if (todayShift.preferredMid != null) {
          debugPrint('   선호 수면 중간: ${todayShift.preferredMid.toString()}');
        }
        
        // 주간 스케줄과 함께 전달
        sleepProvider.computeTodayPlanForShift(
          shift: todayShift,
          weeklySchedule: schedule,
          dayStartHour: settingsProvider.dayStartHour,
        );
        
        // 생성된 계획 확인
        final plan = sleepProvider.lastDailyPlan;
        if (plan != null) {
          debugPrint('   ✅ 계획 생성 완료:');
          debugPrint('      수면 시작: ${plan.mainSleepStart.toString()}');
          debugPrint('      수면 종료: ${plan.mainSleepEnd.toString()}');
          debugPrint('      카페인 컷오프: ${plan.caffeineCutoff.toString()}');
          debugPrint('      취침 준비: ${plan.winddownStart.toString()}');
        } else {
          debugPrint('   ⚠️ 계획 생성 실패 - 근무 시간대일 수 있음');
        }
      } else {
        debugPrint('   ⚠️ 오늘 근무 정보 없음 - 주간 스케줄만 전달');
        // 오늘 근무 정보는 없지만 주간 스케줄은 있으므로 스케줄만 전달
        sleepProvider.computeTodayPlanForShift(
          shift: null,
          weeklySchedule: schedule,
          dayStartHour: settingsProvider.dayStartHour,
        );
      }
    } else {
      debugPrint('   ⚠️ 주간 스케줄 없음 - 기본 휴무로 처리');
      // 스케줄이 아예 없으면 기본 휴무로 처리 (오늘 날짜 사용)
      final defaultOff = ShiftInfo.off(preferredMid: DateTime(now.year, now.month, now.day, 3, 0));
      sleepProvider.computeTodayPlanForShift(
        shift: defaultOff,
        weeklySchedule: null,
        dayStartHour: settingsProvider.dayStartHour,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SleepProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final duration = provider.getTodaySleepDuration(settingsProvider.dayStartHour);
    final progress = provider.getTodayProgress(settingsProvider.dayStartHour, settingsProvider.dailyTargetHours);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Z-Maker'),
        actions: [
          // 클라우드 상태 표시 (로그인 상태일 때만)
          if (authProvider.isAuthenticated)
            IconButton(
              icon: Icon(Icons.cloud_done, color: Colors.green.shade400),
              tooltip: '클라우드 동기화됨',
              onPressed: () async {
                await provider.syncWithFirestore();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('동기화 완료! ☁️')),
                  );
                }
              },
            ),

          // 로그아웃 버튼 (로그인 상태일 때만)
          if (authProvider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: '로그아웃',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('로그아웃 하시겠습니까?\n로컬 데이터는 유지됩니다.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('로그아웃'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await authProvider.signOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그아웃 되었습니다')),
                  );
                }
              },
            ),

          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '설정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTodaySummary(
                    context, duration, progress, settingsProvider.dailyTargetHours),
                const SizedBox(height: 16),
                // 적응형 수면 추천 카드 추가
                _buildAdaptiveRecommendationCard(context),
                const SizedBox(height: 16),
                const DailyTipCard(),
                const SizedBox(height: 16),
                _buildFeatureGrid(context),
                const SizedBox(height: 16),
                _buildEntryList(context),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('수면 추가'),
      ),
    );
  }

  /* ===================== Today Summary ====================== */

  Widget _buildTodaySummary(
    BuildContext context,
    Duration duration,
    double progress,
    int targetHours,
  ) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘의 수면',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text('$h시간 $m분 / $targetHours시간'),
                  const SizedBox(height: 8),
                  Text(
                    progress >= 1
                        ? '수면 목표를 달성했습니다! 😴'
                        : '오늘의 목표를 달성하기 위해 조금 더 자야 합니다.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ===================== Feature Grid ====================== */

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlarmScreen()),
          ),
          child: _buildFeatureCardWidget(
            '알람',
            Icons.alarm,
            const [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SleepMusicScreen()),
          ),
          child: _buildFeatureCardWidget(
            '수면 음악',
            Icons.music_note,
            const [Color(0xFF11998e), Color(0xFF38ef7d)],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          ),
          child: _buildFeatureCardWidget(
            '달력',
            Icons.calendar_today,
            const [Color(0xFFf093fb), Color(0xFFf5576c)],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailySuggestionsScreen()),
          ),
          child: _buildFeatureCardWidget(
            '수면 팁',
            Icons.tips_and_updates,
            const [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnvironmentCheckerScreen()),
          ),
          child: _buildFeatureCardWidget(
            '환경 체커',
            Icons.nightlight_round,
            const [Color(0xFF2c3e50), Color(0xFF4ca1af)],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LightControlScreen()),
          ),
          child: _buildFeatureCardWidget(
            '조명 제어',
            Icons.lightbulb_outline,
            const [Color(0xFFf7971e), Color(0xFFffd200)],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AutoReplySettingsScreen()),
          ),
          child: _buildFeatureCardWidget(
            '자동 응답',
            Icons.message_outlined,
            const [Color(0xFF9C27B0), Color(0xFFE91E63)],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IntegratedSleepManagementScreen()),
          ),
          child: _buildFeatureCardWidget(
            '야간 근무',
            Icons.work_history,
            const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCardWidget(
      String title, IconData icon, List<Color> gradientColors) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ===================== Adaptive Recommendation Card ====================== */

  Widget _buildAdaptiveRecommendationCard(BuildContext context) {
    return Consumer3<SleepProvider, ScheduleProvider, SettingsProvider>(
      builder: (context, sleepProvider, scheduleProvider, settingsProvider, _) {
        final plan = sleepProvider.lastDailyPlan;
        
        // 계획이 없고, Consumer가 처음 호출되었을 때만 자동으로 생성 시도 (무한 루프 방지)
        // Consumer 내부에서 직접 _updateTodayPlan을 호출하지 않고, 
        // initState에서만 호출하도록 변경하여 무한 루프 방지
        
        if (plan == null) {
          return Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        '오늘의 적응형 수면 추천',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '근무 정보를 입력하거나 수면 기록을 추가하면\n맞춤형 수면 계획이 자동으로 생성됩니다.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IntegratedSleepManagementScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('근무 정보 입력하러 가기'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sleepDuration = plan.mainSleepEnd.difference(plan.mainSleepStart);
        final sleepHours = sleepDuration.inHours;
        final sleepMinutes = sleepDuration.inMinutes.remainder(60);
        
        String formatTime(DateTime dt) {
          return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '오늘의 적응형 수면 추천',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyPlanScreen(),
                            ),
                          );
                        },
                        tooltip: '전체 계획 보기',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 수면 시간
                  _buildRecommendationRow(
                    icon: Icons.bedtime,
                    label: '수면 시간',
                    value: '${formatTime(plan.mainSleepStart)} - ${formatTime(plan.mainSleepEnd)}',
                    subValue: '($sleepHours시간 $sleepMinutes분)',
                  ),
                  const SizedBox(height: 12),
                  
                  // 카페인 컷오프
                  _buildRecommendationRow(
                    icon: Icons.coffee,
                    label: '카페인 컷오프',
                    value: formatTime(plan.caffeineCutoff),
                    subValue: '이후 카페인 자제',
                  ),
                  const SizedBox(height: 12),
                  
                  // 취침 준비
                  _buildRecommendationRow(
                    icon: Icons.nightlight,
                    label: '취침 준비',
                    value: formatTime(plan.winddownStart),
                    subValue: '부터 시작',
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailyPlanScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('전체 계획 보기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationRow({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subValue != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      subValue,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /* ===================== Entry List ====================== */

  Widget _buildEntryList(BuildContext context) {
    return Consumer<SleepProvider>(
      builder: (context, provider, _) {
        if (provider.entries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
              child: Text(
              '아직 수면 기록이 없습니다.\n+ 버튼을 눌러 추가하세요.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.entries.length,
          itemBuilder: (context, index) {
            final entry = provider.entries[index];
            return Dismissible(
              key: Key(entry.id ?? '${entry.sleepTime}_${entry.wakeTime}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              confirmDismiss: (direction) async {
                // 삭제 확인
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('수면 기록 삭제'),
                    content: const Text('이 수면 기록을 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('취소'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              onDismissed: (direction) async {
                // 삭제 실행
                final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
                final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                
                await provider.deleteEntry(entry);
                
                // 주간 스케줄 업데이트 (스케줄이 없을 때만 자동 생성)
                if (provider.entries.isNotEmpty) {
                  await scheduleProvider.generateScheduleFromSleepEntries(
                    provider.entries,
                    dayStartHour: settingsProvider.dayStartHour,
                    force: false, // 기존 스케줄이 있으면 덮어쓰지 않음
                  );
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('수면 기록이 삭제되었습니다'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: GestureDetector(
                onLongPress: () {
                  // 진동 피드백
                  HapticFeedback.mediumImpact();
                  // 수정 다이얼로그 표시
                  _showEditEntryDialog(context, entry);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      entry.isNightShift ? Icons.dark_mode : Icons.wb_sunny,
                      color: entry.isNightShift ? Colors.indigo : Colors.orange,
                    ),
                    title: Text(
                      '${_formatDateTime(entry.sleepTime)} → ${_formatDateTime(entry.wakeTime)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('수면 시간: ${entry.formattedDuration}'),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /* ===================== Edit Entry Dialog ====================== */

  Future<void> _showEditEntryDialog(BuildContext context, SleepEntry entry) async {
    DateTime? sleepTime = entry.sleepTime;
    DateTime? wakeTime = entry.wakeTime;
    bool isNightShift = entry.isNightShift;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('수면 기록 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _loadSleepApiData(context, setState,
                              (sleep, wake) {
                            sleepTime = sleep;
                            wakeTime = wake;
                          });
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('수면 API에서 불러오기'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDateTimePicker(
                      context: context,
                      label: '취침 시간',
                      value: sleepTime,
                      onTap: () async {
                        final result = await _pickDateTime(context, initialDateTime: sleepTime);
                        if (result != null) setState(() => sleepTime = result);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDateTimePicker(
                      context: context,
                      label: '기상 시간',
                      value: wakeTime,
                      onTap: () async {
                        final result = await _pickDateTime(context, initialDateTime: wakeTime);
                        if (result != null) setState(() => wakeTime = result);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('야간 근무 수면?'),
                        const Spacer(),
                        Switch(
                          value: isNightShift,
                          onChanged: (v) => setState(() => isNightShift = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (sleepTime == null || wakeTime == null) return;
                    if (wakeTime!.isBefore(sleepTime!)) return;

                    final provider =
                        Provider.of<SleepProvider>(context, listen: false);
                    final scheduleProvider =
                        Provider.of<ScheduleProvider>(context, listen: false);
                    
                    // 수면 기록 수정
                    await provider.updateEntry(
                      entry,
                      SleepEntry(
                        id: entry.id, // ID 유지
                        sleepTime: sleepTime!,
                        wakeTime: wakeTime!,
                        isNightShift: isNightShift,
                      ),
                    );
                    
                    // 주간 스케줄 자동 생성 (수면 기록 기반, 스케줄이 없을 때만)
                    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                    final hadSchedule = scheduleProvider.currentSchedule != null;
                    await scheduleProvider.generateScheduleFromSleepEntries(
                      provider.entries,
                      dayStartHour: settingsProvider.dayStartHour,
                      force: false, // 기존 스케줄이 있으면 덮어쓰지 않음
                    );
                    
                    if (context.mounted) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final scheduleUpdated = !hadSchedule && scheduleProvider.currentSchedule != null;
                      
                      if (authProvider.isAuthenticated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(scheduleUpdated 
                              ? '수면 기록이 수정되었습니다 ✏️\n주간 스케줄이 자동 생성되었습니다 📅'
                              : '수면 기록이 수정되었습니다 ✏️'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(scheduleUpdated 
                              ? '수면 기록이 수정되었습니다 ✏️\n주간 스케줄이 자동 생성되었습니다 📅'
                              : '수면 기록이 수정되었습니다 ✏️'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /* ===================== Add Entry Dialog ====================== */

  Future<void> _showAddEntryDialog(BuildContext context) async {
    DateTime? sleepTime;
    DateTime? wakeTime;
    bool isNightShift = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('수면 기록 추가'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _loadSleepApiData(context, setState,
                              (sleep, wake) {
                            sleepTime = sleep;
                            wakeTime = wake;
                          });
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('수면 API에서 불러오기'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDateTimePicker(
                      context: context,
                      label: '취침 시간',
                      value: sleepTime,
                      onTap: () async {
                        final result = await _pickDateTime(context);
                        if (result != null) setState(() => sleepTime = result);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDateTimePicker(
                      context: context,
                      label: '기상 시간',
                      value: wakeTime,
                      onTap: () async {
                        final result = await _pickDateTime(context);
                        if (result != null) setState(() => wakeTime = result);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('야간 근무 수면?'),
                        const Spacer(),
                        Switch(
                          value: isNightShift,
                          onChanged: (v) => setState(() => isNightShift = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (sleepTime == null || wakeTime == null) return;
                    if (wakeTime!.isBefore(sleepTime!)) return;

                    final provider =
                        Provider.of<SleepProvider>(context, listen: false);
                    final scheduleProvider =
                        Provider.of<ScheduleProvider>(context, listen: false);
                    
                    // 수면 기록 저장
                    await provider.addEntry(
                      SleepEntry(
                        sleepTime: sleepTime!,
                        wakeTime: wakeTime!,
                        isNightShift: isNightShift,
                      ),
                    );
                    
                    // 주간 스케줄 자동 생성 (수면 기록 기반, 스케줄이 없을 때만)
                    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                    final hadSchedule = scheduleProvider.currentSchedule != null;
                    await scheduleProvider.generateScheduleFromSleepEntries(
                      provider.entries,
                      dayStartHour: settingsProvider.dayStartHour,
                      force: false, // 기존 스케줄이 있으면 덮어쓰지 않음
                    );
                    
                    if (mounted) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final scheduleUpdated = !hadSchedule && scheduleProvider.currentSchedule != null;
                      
                      if (authProvider.isAuthenticated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(scheduleUpdated 
                              ? '수면 기록이 클라우드에 저장되었습니다 ☁️\n주간 스케줄이 자동 생성되었습니다 📅'
                              : '수면 기록이 클라우드에 저장되었습니다 ☁️'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(scheduleUpdated 
                              ? '수면 기록이 저장되었습니다\n주간 스케줄이 자동 생성되었습니다 📅'
                              : '수면 기록이 저장되었습니다'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /* ===================== DateTime Helpers ====================== */

  Widget _buildDateTimePicker({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value == null ? 'Select...' : _formatDateTime(value)),
      trailing: const Icon(Icons.schedule),
      onTap: onTap,
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context, {DateTime? initialDateTime}) async {
    final now = DateTime.now();
    final initial = initialDateTime ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} '
        '${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  /* ===================== Sleep API 데이터 로드 ====================== */

  Future<void> _loadSleepApiData(
    BuildContext dialogContext,
    StateSetter setState,
    Function(DateTime, DateTime) onDataLoaded,
  ) async {
    // 권한 확인
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      status = await Permission.activityRecognition.request();
    }

    if (!status.isGranted) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('활동 인식 권한이 필요합니다.\n설정에서 권한을 허용해주세요.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // 로딩 다이얼로그 표시
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      debugPrint('🚀 Sleep API 데이터 로드 시작');
      
      // Sleep API 서비스 초기화
      await SleepApiService.instance.init();
      debugPrint('✅ SleepApiService 초기화 완료');
      
      // Sleep API 구독 요청
      debugPrint('📡 Sleep API 구독 요청 중...');
      final subscriptionSuccess = await SleepApiService.instance.requestSleepUpdates();
      
      if (!subscriptionSuccess) {
        debugPrint('❌ Sleep API 구독 실패');
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text(
              '수면 API 구독에 실패했습니다.\n'
              '가능한 원인:\n'
              '• Google Play Services가 설치/업데이트되지 않음\n'
              '• 기기가 Sleep API를 지원하지 않음\n'
              '• Google Fit 또는 건강 앱에서 수면 데이터가 없음\n\n'
              '기본 추정값을 사용합니다.'
            ),
            duration: Duration(seconds: 5),
          ),
        );
        final defaultData = SleepApiService.instance.getDefaultEstimate();
        setState(() {
          onDataLoaded(defaultData['sleepTime']!, defaultData['wakeTime']!);
        });
        return;
      }

      debugPrint('✅ Sleep API 구독 성공');
      debugPrint('⏳ SleepReceiver가 데이터를 저장할 때까지 대기 중... (2초)');
      
      // 데이터가 수집될 때까지 잠시 대기 (Google Play Services가 데이터를 처리하고 SharedPreferences에 저장되는 시간 필요)
      // SleepReceiver가 BroadcastReceiver이므로 약간의 지연이 필요
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('📖 최신 수면 데이터 읽기 시작...');
      // 최신 수면 데이터 가져오기
      final apiData = await SleepApiService.instance.getLatestSleepData();
      debugPrint('📊 읽기 결과: ${apiData != null ? "데이터 발견" : "데이터 없음"}');

      Navigator.pop(dialogContext);

      if (apiData != null) {
        setState(() {
          onDataLoaded(apiData['sleepTime']!, apiData['wakeTime']!);
        });
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text('✅ Google Sleep API에서 수면 데이터를 불러왔습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final defaultData = SleepApiService.instance.getDefaultEstimate();
        setState(() {
          onDataLoaded(defaultData['sleepTime']!, defaultData['wakeTime']!);
        });
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ 수면 API 데이터를 찾을 수 없습니다.\n'
              'Google Fit이나 건강 앱에서 수면 데이터를 기록해야 합니다.\n'
              '기본 추정값을 사용합니다.'
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(dialogContext);
      debugPrint('Sleep API 로드 오류: $e');
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text(
            '오류가 발생했습니다: ${e.toString()}\n'
            '기본 추정값을 사용합니다.'
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      final defaultData = SleepApiService.instance.getDefaultEstimate();
      setState(() {
        onDataLoaded(defaultData['sleepTime']!, defaultData['wakeTime']!);
      });
    }
  }
}
