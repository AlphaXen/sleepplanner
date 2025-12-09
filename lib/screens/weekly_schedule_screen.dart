import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weekly_schedule.dart';
import '../models/shift_info.dart';
import '../providers/schedule_provider.dart';
import '../providers/sleep_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/date_utils.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  final Map<int, ShiftInfo?> _shifts = {};
  DateTime _weekStart = _getMonday(DateTime.now());

  static DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    // 초기값 설정
    for (int i = 0; i < 7; i++) {
      _shifts[i] = null;
    }
    
    // 저장된 스케줄 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingSchedule();
    });
  }

  Future<void> _loadExistingSchedule() async {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    
    // 스케줄 로드가 완료될 때까지 대기
    await scheduleProvider.waitForLoad();
    
    final existingSchedule = scheduleProvider.currentSchedule;
    
    if (existingSchedule != null) {
      if (mounted) {
        setState(() {
          _weekStart = existingSchedule.weekStart;
          _shifts.clear();
          _shifts.addAll(existingSchedule.shifts);
          
          // 빈 슬롯 채우기
          for (int i = 0; i < 7; i++) {
            if (!_shifts.containsKey(i)) {
              _shifts[i] = null;
            }
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장된 스케줄을 불러왔습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _setShift(int dayIndex, ShiftInfo shift) {
    setState(() {
      _shifts[dayIndex] = shift;
    });
  }

  void _removeShift(int dayIndex) {
    setState(() {
      _shifts[dayIndex] = null;
    });
  }

  Future<void> _saveSchedule() async {
    final validShifts = <int, ShiftInfo>{};
    _shifts.forEach((key, value) {
      if (value != null) {
        validShifts[key] = value;
      }
    });

    if (validShifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 이상의 근무를 설정해주세요')),
      );
      return;
    }

    final schedule = WeeklySchedule(
      weekStart: _weekStart,
      shifts: validShifts,
    );

    try {
      // Provider에 저장
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      
      await scheduleProvider.saveSchedule(schedule);
      
      // 스케줄 저장 후 적응형 수면 계획 자동 재계산
      final now = DateTime.now();
      final today = getTodayKey(settingsProvider.dayStartHour);
      final todayShift = schedule.getShiftForDate(today);
      
      if (todayShift != null) {
        sleepProvider.computeTodayPlanForShift(
          shift: todayShift,
          weeklySchedule: schedule,
          dayStartHour: settingsProvider.dayStartHour,
        );
      } else {
        // 오늘 근무 정보가 없으면 기본 휴무로 처리
        final defaultOff = ShiftInfo.off(preferredMid: DateTime(now.year, now.month, now.day, 3, 0));
        sleepProvider.computeTodayPlanForShift(
          shift: defaultOff,
          weeklySchedule: schedule,
          dayStartHour: settingsProvider.dayStartHour,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주간 스케줄 저장 완료\n패턴: ${schedule.detectPattern()}\n적응형 수면 계획이 자동으로 업데이트되었습니다'),
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, schedule);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDayName(int dayIndex) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[dayIndex];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('주간 근무 스케줄'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearSchedule,
            tooltip: '스케줄 초기화',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: '도움말',
          ),
        ],
      ),
      body: Column(
        children: [
          // 주간 선택
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_weekStart.month}/${_weekStart.day} ~ ${_weekStart.add(const Duration(days: 6)).month}/${_weekStart.add(const Duration(days: 6)).day}',
                    style: theme.textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _weekStart =
                                _weekStart.subtract(const Duration(days: 7));
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _weekStart = _weekStart.add(const Duration(days: 7));
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 일별 근무 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 7,
              itemBuilder: (context, index) {
                return _buildDayCard(index);
              },
            ),
          ),

          // 저장 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _saveSchedule,
                icon: const Icon(Icons.save),
                label: const Text('스케줄 저장', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(int dayIndex) {
    final theme = Theme.of(context);
    final shift = _shifts[dayIndex];
    final dayDate = _weekStart.add(Duration(days: dayIndex));
    final isToday = dayDate.day == DateTime.now().day &&
        dayDate.month == DateTime.now().month;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isToday ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 요일
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getDayName(dayIndex),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 근무 정보
            Expanded(
              child: shift == null
                  ? Text(
                      '근무 미설정',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getShiftIcon(shift.type),
                            const SizedBox(width: 8),
                            Text(
                              _getShiftTypeName(shift.type),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (shift.type != ShiftType.off) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_formatTime(shift.shiftStart!)} ~ ${_formatTime(shift.shiftEnd!)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
            ),

            // 액션 버튼
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showShiftDialog(dayIndex),
                ),
                if (shift != null)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeShift(dayIndex),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getShiftIcon(ShiftType type) {
    switch (type) {
      case ShiftType.day:
        return const Icon(Icons.wb_sunny, color: Colors.orange);
      case ShiftType.night:
        return const Icon(Icons.nightlight, color: Colors.indigo);
      case ShiftType.off:
        return const Icon(Icons.weekend, color: Colors.green);
    }
  }

  String _getShiftTypeName(ShiftType type) {
    switch (type) {
      case ShiftType.day:
        return '주간 근무';
      case ShiftType.night:
        return '야간 근무';
      case ShiftType.off:
        return '휴무';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showShiftDialog(int dayIndex) {
    final dayDate = _weekStart.add(Duration(days: dayIndex));
    final existingShift = _shifts[dayIndex];
    
    ShiftType selectedType = existingShift?.type ?? ShiftType.day;
    
    // 기존 스케줄이 있으면 그것을 기반으로 초기값 설정, 없으면 기본값 사용
    DateTime startTime;
    DateTime endTime;
    
    if (existingShift != null && existingShift.shiftStart != null && existingShift.shiftEnd != null) {
      // 기존 스케줄의 시간 정보 사용 (날짜는 dayDate로 교체)
      startTime = DateTime(
        dayDate.year,
        dayDate.month,
        dayDate.day,
        existingShift.shiftStart!.hour,
        existingShift.shiftStart!.minute,
      );
      endTime = DateTime(
        dayDate.year,
        dayDate.month,
        dayDate.day,
        existingShift.shiftEnd!.hour,
        existingShift.shiftEnd!.minute,
      );
      
      // 야간 근무의 경우 종료 시간이 다음날일 수 있음
      if (existingShift.type == ShiftType.night && endTime.isBefore(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }
    } else {
      // 기본값: 주간 근무는 9-17시, 야간 근무는 22-6시
      if (selectedType == ShiftType.night) {
        startTime = DateTime(dayDate.year, dayDate.month, dayDate.day, 22, 0);
        endTime = DateTime(dayDate.year, dayDate.month, dayDate.day, 6, 0).add(const Duration(days: 1));
      } else {
        startTime = DateTime(dayDate.year, dayDate.month, dayDate.day, 9, 0);
        endTime = DateTime(dayDate.year, dayDate.month, dayDate.day, 17, 0);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${_getDayName(dayIndex)}요일 근무 설정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 근무 유형 선택
                DropdownButtonFormField<ShiftType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: '근무 유형',
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
                      child: Text('휴무'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        selectedType = v;
                        // 근무 유형이 변경되면 기본 시간으로 재설정
                        if (v == ShiftType.night) {
                          startTime = DateTime(dayDate.year, dayDate.month, dayDate.day, 22, 0);
                          endTime = DateTime(dayDate.year, dayDate.month, dayDate.day, 6, 0).add(const Duration(days: 1));
                        } else if (v == ShiftType.day) {
                          startTime = DateTime(dayDate.year, dayDate.month, dayDate.day, 9, 0);
                          endTime = DateTime(dayDate.year, dayDate.month, dayDate.day, 17, 0);
                        }
                      });
                    }
                  },
                ),

                if (selectedType != ShiftType.off) ...[
                  const SizedBox(height: 16),
                  // 시작 시간
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('시작 시간'),
                    subtitle: Text(_formatTime(startTime)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startTime),
                      );
                      if (time != null) {
                        setState(() {
                          startTime = DateTime(
                            dayDate.year,
                            dayDate.month,
                            dayDate.day,
                            time.hour,
                            time.minute,
                          );
                          // 야간 근무의 경우 종료 시간이 다음날일 수 있음
                          if (selectedType == ShiftType.night && endTime.isBefore(startTime)) {
                            endTime = DateTime(
                              dayDate.year,
                              dayDate.month,
                              dayDate.day,
                              endTime.hour,
                              endTime.minute,
                            ).add(const Duration(days: 1));
                          }
                        });
                      }
                    },
                  ),

                  // 종료 시간
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('종료 시간'),
                    subtitle: Text(_formatTime(endTime)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endTime),
                      );
                      if (time != null) {
                        setState(() {
                          // 야간 근무의 경우 종료 시간이 시작 시간보다 작으면 다음날로 해석
                          if (selectedType == ShiftType.night && time.hour < startTime.hour) {
                            endTime = DateTime(
                              dayDate.year,
                              dayDate.month,
                              dayDate.day,
                              time.hour,
                              time.minute,
                            ).add(const Duration(days: 1));
                          } else {
                            endTime = DateTime(
                              dayDate.year,
                              dayDate.month,
                              dayDate.day,
                              time.hour,
                              time.minute,
                            );
                          }
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
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                ShiftInfo shift;
                if (selectedType == ShiftType.off) {
                  // 휴무일은 해당 날짜의 새벽 3시를 preferredMid로 설정
                  shift = ShiftInfo.off(
                    preferredMid: DateTime(dayDate.year, dayDate.month, dayDate.day, 3, 0),
                  );
                } else if (selectedType == ShiftType.day) {
                  shift = ShiftInfo.day(
                    shiftStart: startTime,
                    shiftEnd: endTime,
                  );
                } else {
                  shift = ShiftInfo.night(
                    shiftStart: startTime,
                    shiftEnd: endTime,
                  );
                }
                _setShift(dayIndex, shift);
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearSchedule() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('스케줄 초기화'),
        content: const Text('저장된 모든 스케줄을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      await scheduleProvider.clearSchedule();
      
      setState(() {
        for (int i = 0; i < 7; i++) {
          _shifts[i] = null;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스케줄이 초기화되었습니다')),
        );
      }
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주간 스케줄 가이드'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📅 일주일 근무 패턴 입력',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('월요일부터 일요일까지의 근무 일정을 입력하세요. 시스템이 자동으로 최적의 수면 계획을 생성합니다.'),
              SizedBox(height: 16),
              Text(
                '☀️ 주간 근무',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('낮 시간대 근무 (예: 09:00-18:00)'),
              SizedBox(height: 12),
              Text(
                '🌙 야간 근무',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('밤 시간대 근무 (예: 22:00-07:00)\n낮잠 추천, 빛 차단 전략 등이 제공됩니다.'),
              SizedBox(height: 12),
              Text(
                '🏖️ 휴무',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('쉬는 날. 수면 부채 회복 전략이 제공됩니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

