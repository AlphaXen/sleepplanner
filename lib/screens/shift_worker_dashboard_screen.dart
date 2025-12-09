import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../providers/schedule_provider.dart';
import '../services/shift_worker_service.dart';
import '../models/weekly_schedule.dart';
import '../models/shift_info.dart';
import '../models/daily_plan.dart';
import 'weekly_schedule_screen.dart';
import 'daily_plan_screen.dart';

class ShiftWorkerDashboardScreen extends StatefulWidget {
  final bool hideAppBar;
  
  const ShiftWorkerDashboardScreen({super.key, this.hideAppBar = false});

  @override
  State<ShiftWorkerDashboardScreen> createState() =>
      _ShiftWorkerDashboardScreenState();
}

class _ShiftWorkerDashboardScreenState
    extends State<ShiftWorkerDashboardScreen> {
  final _service = ShiftWorkerService();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 수면 기록으로부터 스케줄 자동 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateScheduleFromEntries();
    });
  }

  Future<void> _generateScheduleFromEntries() async {
    final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    
    if (sleepProvider.entries.isNotEmpty) {
      await scheduleProvider.generateScheduleFromSleepEntries(sleepProvider.entries);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleepProvider = Provider.of<SleepProvider>(context);
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final currentSchedule = scheduleProvider.currentSchedule;

    // 수면 부채 계산
    final sleepDebts = _service.calculateSleepDebt(
      entries: sleepProvider.entries,
      targetHours: sleepProvider.adaptiveParams.tSleep,
      days: 7,
    );
    final cumulativeDebt = _service.calculateCumulativeDebt(sleepDebts);

    // 평균 수면 시간 계산
    final avgSleepHours = sleepDebts.isEmpty
        ? 0.0
        : sleepDebts.map((d) => d.actualHours).reduce((a, b) => a + b) /
            sleepDebts.length;

    // 수면 일관성 계산
    final sleepConsistency = _service.calculateSleepConsistency(sleepDebts);

    // 연속 야간 근무 계산
    final consecutiveNightShifts =
        _service.calculateConsecutiveNightShifts(currentSchedule);

    // 건강 점수 계산
    final healthScore = _service.calculateShiftWorkerHealthScore(
      avgSleepHours: avgSleepHours,
      sleepDebt: cumulativeDebt,
      sleepConsistency: sleepConsistency,
      consecutiveNightShifts: consecutiveNightShifts,
    );

    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('야간 노동자 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
              final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
              
              if (sleepProvider.entries.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('수면 기록이 없습니다. 먼저 수면 기록을 추가해주세요.'),
                  ),
                );
                return;
              }
              
              await scheduleProvider.generateScheduleFromSleepEntries(sleepProvider.entries);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '주간 스케줄이 수면 기록으로부터 재생성되었습니다 📅\n패턴: ${scheduleProvider.currentSchedule?.detectPattern() ?? "없음"}',
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
                setState(() {}); // 화면 갱신
              }
            },
            tooltip: '수면 기록으로부터 스케줄 재생성',
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WeeklyScheduleScreen(),
                ),
              );
            },
            tooltip: '주간 스케줄 보기',
          ),
          IconButton(
            icon: const Icon(Icons.event_note),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailyPlanScreen(),
                ),
              );
            },
            tooltip: '일일 계획 보기',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showShiftInputDialog,
            tooltip: '근무 정보 입력',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 데이터 부족 경고
            if (sleepProvider.entries.isEmpty)
              _buildNoDataWarning(),
            if (sleepProvider.entries.isEmpty)
              const SizedBox(height: 16),

            // 건강 점수 카드
            _buildHealthScoreCard(healthScore),
            const SizedBox(height: 16),

            // 근무 스케줄 요약
            if (currentSchedule != null)
              _buildScheduleSummaryCard(currentSchedule),
            if (currentSchedule == null) _buildNoScheduleCard(),
            const SizedBox(height: 16),

            // 수면 부채 카드
            _buildSleepDebtCard(cumulativeDebt, sleepDebts),
            const SizedBox(height: 16),

            // 회복 계획
            _buildRecoveryPlanCard(cumulativeDebt, currentSchedule),
            const SizedBox(height: 16),

            // 낮잠 추천
            if (currentSchedule != null)
              _buildNapRecommendationsCard(
                  currentSchedule, cumulativeDebt, sleepProvider),
            const SizedBox(height: 16),

            // 근무 전환 조언
            if (currentSchedule != null)
              _buildRotationTipsCard(currentSchedule),
            const SizedBox(height: 16),

            // 빛 노출 전략
            if (currentSchedule != null)
              _buildLightStrategyCard(currentSchedule),
            const SizedBox(height: 16),

            // 일일 계획 카드
            _buildDailyPlanCard(),
          ],
        ),
      ),
    );
  }

  void _showShiftInputDialog() {
    ShiftType _dialogType = ShiftType.day;
    DateTime? _dialogShiftStart;
    DateTime? _dialogShiftEnd;
    DateTime? _dialogPreferredMid;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('근무 정보 입력'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<ShiftType>(
                      value: _dialogType,
                      decoration: const InputDecoration(
                        labelText: '근무 유형 선택',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ShiftType.day,
                          child: Text('주간 근무'),
                        ),
                        DropdownMenuItem(
                          value: ShiftType.night,
                          child: Text('야간 근무'),
                        ),
                        DropdownMenuItem(
                          value: ShiftType.off,
                          child: Text('휴무일'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _dialogType = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_dialogType != ShiftType.off) ...[
                      ListTile(
                        title: const Text('근무 시작 시간'),
                        subtitle: Text(
                          _dialogShiftStart == null
                              ? '선택...'
                              : '${_dialogShiftStart!.year}-${_dialogShiftStart!.month.toString().padLeft(2, '0')}-${_dialogShiftStart!.day.toString().padLeft(2, '0')} '
                                  '${_dialogShiftStart!.hour.toString().padLeft(2, '0')}:${_dialogShiftStart!.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.schedule),
                        onTap: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 1),
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(now),
                          );
                          if (time != null) {
                            setState(() {
                              _dialogShiftStart = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('근무 종료 시간'),
                        subtitle: Text(
                          _dialogShiftEnd == null
                              ? '선택...'
                              : '${_dialogShiftEnd!.year}-${_dialogShiftEnd!.month.toString().padLeft(2, '0')}-${_dialogShiftEnd!.day.toString().padLeft(2, '0')} '
                                  '${_dialogShiftEnd!.hour.toString().padLeft(2, '0')}:${_dialogShiftEnd!.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.schedule),
                        onTap: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 1),
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(now),
                          );
                          if (time != null) {
                            setState(() {
                              _dialogShiftEnd = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                      ),
                    ] else ...[
                      ListTile(
                        title: const Text('선호 수면 중간 시간 (휴무일)'),
                        subtitle: Text(
                          _dialogPreferredMid == null
                              ? '선택...'
                              : '${_dialogPreferredMid!.year}-${_dialogPreferredMid!.month.toString().padLeft(2, '0')}-${_dialogPreferredMid!.day.toString().padLeft(2, '0')} '
                                  '${_dialogPreferredMid!.hour.toString().padLeft(2, '0')}:${_dialogPreferredMid!.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.schedule),
                        onTap: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 1),
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(now),
                          );
                          if (time != null) {
                            setState(() {
                              _dialogPreferredMid = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final provider = Provider.of<SleepProvider>(context, listen: false);

                    ShiftInfo shift;
                    if (_dialogType == ShiftType.off) {
                      if (_dialogPreferredMid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('수면 중간 시간을 선택해주세요.')),
                        );
                        return;
                      }
                      shift = ShiftInfo.off(preferredMid: _dialogPreferredMid);
                    } else {
                      if (_dialogShiftStart == null || _dialogShiftEnd == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('근무 시작 및 종료 시간을 선택해주세요.')),
                        );
                        return;
                      }
                      if (_dialogType == ShiftType.day) {
                        shift = ShiftInfo.day(
                          shiftStart: _dialogShiftStart,
                          shiftEnd: _dialogShiftEnd,
                        );
                      } else {
                        shift = ShiftInfo.night(
                          shiftStart: _dialogShiftStart,
                          shiftEnd: _dialogShiftEnd,
                        );
                      }
                    }

                    provider.computeTodayPlanForShift(shift);
                    Navigator.pop(dialogContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DailyPlanScreen()),
                    );
                  },
                  child: const Text('일일 계획 계산'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDailyPlanCard() {
    final sleepProvider = Provider.of<SleepProvider>(context);
    final plan = sleepProvider.lastDailyPlan;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '오늘의 일일 계획',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _showShiftInputDialog,
                  tooltip: '근무 정보 입력',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (plan == null)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '일일 계획이 없습니다.\n근무 정보를 입력하여 계획을 생성하세요.',
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              Text('수면 시간: ${plan.mainSleepStart.hour.toString().padLeft(2, '0')}:${plan.mainSleepStart.minute.toString().padLeft(2, '0')} - ${plan.mainSleepEnd.hour.toString().padLeft(2, '0')}:${plan.mainSleepEnd.minute.toString().padLeft(2, '0')}'),
              const SizedBox(height: 8),
              Text('카페인 컷오프: ${plan.caffeineCutoff.hour.toString().padLeft(2, '0')}:${plan.caffeineCutoff.minute.toString().padLeft(2, '0')}'),
              const SizedBox(height: 8),
              Text('취침 준비: ${plan.winddownStart.hour.toString().padLeft(2, '0')}:${plan.winddownStart.minute.toString().padLeft(2, '0')}'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyPlanScreen()),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('전체 계획 보기'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWarning() {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.onErrorContainer,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '수면 기록이 없습니다',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '홈 화면에서 "Add Sleep" 버튼으로\n수면 기록을 추가해주세요',
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(double score) {
    final scoreColor = _getScoreColor(score);

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scoreColor.withOpacity(0.7), scoreColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '야간 노동자 건강 점수',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              score.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getScoreLabel(score),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSummaryCard(WeeklySchedule schedule) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '주간 근무 패턴',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '패턴: ${schedule.detectPattern()}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPatternStat(
                  '야간',
                  schedule.nightShiftCount.toString(),
                  Colors.indigo,
                ),
                _buildPatternStat(
                  '주간',
                  schedule.dayShiftCount.toString(),
                  Colors.orange,
                ),
                _buildPatternStat(
                  '휴무',
                  schedule.offDaysCount.toString(),
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoScheduleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              '주간 스케줄을 설정해주세요',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '스케줄을 입력하면 맞춤형 수면 계획과\n낮잠 추천을 받을 수 있습니다',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WeeklyScheduleScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('스케줄 설정'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildSleepDebtCard(
      double cumulativeDebt, List<SleepDebt> debts) {
    final theme = Theme.of(context);
    final debtColor = cumulativeDebt > 5
        ? Colors.red
        : cumulativeDebt > 2
            ? Colors.orange
            : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: debtColor),
                const SizedBox(width: 8),
                const Text(
                  '수면 부채',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('누적 부채:'),
                      Text(
                        '(${debts.length}일 기록됨)',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${cumulativeDebt > 0 ? '+' : ''}${cumulativeDebt.toStringAsFixed(1)} 시간',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: debtColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (cumulativeDebt.abs() / 10).clamp(0, 1),
              backgroundColor: Colors.grey.shade300,
              color: debtColor,
            ),
            const SizedBox(height: 12),
            Text(
              _getDebtMessage(cumulativeDebt),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (debts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '평균 수면: ${(debts.map((d) => d.actualHours).reduce((a, b) => a + b) / debts.length).toStringAsFixed(1)}h/일 (기록된 날 기준)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // 디버그 정보 (일별 상세)
              ExpansionTile(
                title: Text(
                  '일별 상세 보기',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
                children: debts.map((debt) {
                  final isToday = debt.date.day == DateTime.now().day &&
                      debt.date.month == DateTime.now().month;
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${debt.date.month}/${debt.date.day} ${isToday ? "(오늘)" : ""}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      '실제: ${debt.actualHours.toStringAsFixed(1)}h / 목표: ${debt.targetHours.toStringAsFixed(1)}h',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      '${debt.debtHours > 0 ? '+' : ''}${debt.debtHours.toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: debt.debtHours > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (debts.length < 7) ...[
              const SizedBox(height: 8),
              Text(
                '💡 ${7 - debts.length}일의 수면 기록이 더 있으면 더 정확한 분석이 가능합니다',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryPlanCard(
      double cumulativeDebt, WeeklySchedule? schedule) {
    final theme = Theme.of(context);
    final plan = _service.createDebtRecoveryPlan(
      cumulativeDebt: cumulativeDebt,
      schedule: schedule,
    );

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.healing,
                    color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  '회복 계획',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan['message'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            if (plan['strategies'] != null) ...[
              const SizedBox(height: 12),
              ...(plan['strategies'] as List).map((strategy) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ',
                            style: TextStyle(
                                color:
                                    theme.colorScheme.onSecondaryContainer)),
                        Expanded(
                          child: Text(
                            strategy,
                            style: TextStyle(
                                color:
                                    theme.colorScheme.onSecondaryContainer),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (plan['recoveryMessage'] != null) ...[
              const SizedBox(height: 8),
              Text(
                plan['recoveryMessage'],
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNapRecommendationsCard(WeeklySchedule schedule,
      double sleepDebt, SleepProvider sleepProvider) {
    final today = DateTime.now();
    final todayShift = schedule.getShiftForDate(today);
    final tomorrowShift =
        schedule.getShiftForDate(today.add(const Duration(days: 1)));

    if (todayShift == null) {
      return const SizedBox.shrink();
    }

    final naps = _service.recommendNaps(
      todayShift: todayShift,
      tomorrowShift: tomorrowShift,
      sleepDebt: sleepDebt,
      params: sleepProvider.adaptiveParams,
    );

    if (naps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  '낮잠 추천',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...naps.map((nap) => _buildNapItem(nap)),
          ],
        ),
      ),
    );
  }

  Widget _buildNapItem(NapRecommendation nap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_getNapIcon(nap.type), color: _getNapColor(nap.type)),
        title: Text(
          '${nap.napTime.hour.toString().padLeft(2, '0')}:${nap.napTime.minute.toString().padLeft(2, '0')} (${nap.duration.inMinutes}분)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(nap.reason),
      ),
    );
  }

  Widget _buildRotationTipsCard(WeeklySchedule schedule) {
    final today = DateTime.now();
    final todayShift = schedule.getShiftForDate(today);
    final tomorrowShift =
        schedule.getShiftForDate(today.add(const Duration(days: 1)));

    if (todayShift == null || tomorrowShift == null) {
      return const SizedBox.shrink();
    }

    final tips = _service.getRotationAdaptationTips(
      currentShift: todayShift.type,
      nextShift: tomorrowShift.type,
    );

    if (tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  '근무 전환 조언',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLightStrategyCard(WeeklySchedule schedule) {
    final today = DateTime.now();
    final todayShift = schedule.getShiftForDate(today);

    if (todayShift == null) {
      return const SizedBox.shrink();
    }

    final strategy = _service.generateLightExposureStrategy(
      shift: todayShift,
      now: today,
    );

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  '빛 노출 전략',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...strategy.entries.map((entry) {
              final value = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value['description'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(value['recommendation'] ?? ''),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return '우수 - 건강한 수면 패턴';
    if (score >= 60) return '양호 - 개선 가능';
    if (score >= 40) return '주의 - 개선 필요';
    return '위험 - 즉시 조치 필요';
  }

  String _getDebtMessage(double debt) {
    if (debt <= 0) return '수면 부채 없음! 훌륭합니다!';
    if (debt <= 2) return '경미한 수면 부채. 휴무일에 조금 더 자세요.';
    if (debt <= 5) return '중등도 수면 부채. 회복 계획을 따르세요.';
    return '심각한 수면 부채! 즉시 회복이 필요합니다.';
  }

  IconData _getNapIcon(NapType type) {
    switch (type) {
      case NapType.power:
        return Icons.flash_on;
      case NapType.short:
        return Icons.bedtime;
      case NapType.long:
        return Icons.hotel;
    }
  }

  Color _getNapColor(NapType type) {
    switch (type) {
      case NapType.power:
        return Colors.orange;
      case NapType.short:
        return Colors.blue;
      case NapType.long:
        return Colors.purple;
    }
  }
}

