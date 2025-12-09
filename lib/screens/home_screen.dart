import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/sleep_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../models/sleep_entry.dart';
import '../widgets/daily_tip_card.dart';
import '../services/sleep_api_service.dart';
import 'stats_screen.dart';
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
      
      // Firebase에서 데이터 로드 후 스케줄 자동 생성
      if (authProvider.isAuthenticated) {
        await sleepProvider.syncWithFirestore();
        if (sleepProvider.entries.isNotEmpty) {
          await scheduleProvider.generateScheduleFromSleepEntries(sleepProvider.entries);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SleepProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final duration = provider.todaySleepDuration;
    final progress = provider.todayProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Planner'),
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
            icon: const Icon(Icons.show_chart),
            tooltip: '통계/그래프',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
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
                    context, duration, progress, provider.dailyTargetHours),
                const SizedBox(height: 16),
                const DailyTipCard(),
                const SizedBox(height: 16),
                _buildFeatureGrid(context),
                const SizedBox(height: 16),
                _buildTargetEditor(context, provider),
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
            '환경',
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
            'AI 분석 & 야간 근무',
            Icons.psychology,
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

  /* ===================== Target Editor ====================== */

  Widget _buildTargetEditor(BuildContext context, SleepProvider provider) {
    final controller =
        TextEditingController(text: provider.dailyTargetHours.toString());
    return Row(
      children: [
        const Text('일일 목표 (시간):'),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              final h = int.tryParse(v);
              if (h != null && h > 0 && h <= 24) {
                provider.setDailyTarget(h);
              }
            },
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
            final e = provider.entries[index];
            return ListTile(
              leading: Icon(e.isNightShift ? Icons.dark_mode : Icons.wb_sunny),
              title: Text(
                '${_formatDateTime(e.sleepTime)} → ${_formatDateTime(e.wakeTime)}',
              ),
              subtitle: Text('수면 시간: ${e.formattedDuration}'),
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
                    
                    // 주간 스케줄 자동 생성 (수면 기록 기반)
                    await scheduleProvider.generateScheduleFromSleepEntries(
                      provider.entries,
                    );
                    
                    if (mounted) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.isAuthenticated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('수면 기록이 클라우드에 저장되었습니다 ☁️\n주간 스케줄이 자동 생성되었습니다 📅'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('수면 기록이 저장되었습니다\n주간 스케줄이 자동 생성되었습니다 📅'),
                            duration: Duration(seconds: 2),
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

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
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
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      status = await Permission.activityRecognition.request();
    }

    if (!status.isGranted) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
            content: Text('Activity Recognition permission required')),
      );
      return;
    }

    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    await SleepApiService.instance.requestSleepUpdates();
    await Future.delayed(const Duration(milliseconds: 500));

    final apiData = await SleepApiService.instance.getLatestSleepData();

    Navigator.pop(dialogContext);

    if (apiData != null) {
      setState(() {
        onDataLoaded(apiData['sleepTime']!, apiData['wakeTime']!);
      });
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('Loaded data from Google Sleep API')),
      );
    } else {
      final defaultData = SleepApiService.instance.getDefaultEstimate();
      setState(() {
        onDataLoaded(defaultData['sleepTime']!, defaultData['wakeTime']!);
      });
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
            content: Text('API 데이터를 찾을 수 없습니다. 기본값을 사용합니다')),
      );
    }
  }
}
