import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sleep_provider.dart';
import '../providers/schedule_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final sleepProvider = Provider.of<SleepProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 일일 목표 수면시간 설정
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bedtime, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          '일일 목표 수면시간',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${settingsProvider.dailyTargetHours}시간',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: settingsProvider.dailyTargetHours.toDouble(),
                      min: 4,
                      max: 12,
                      divisions: 8,
                      label: '${settingsProvider.dailyTargetHours}시간',
                      onChanged: (value) async {
                        await settingsProvider.setDailyTargetHours(value.toInt());
                        sleepProvider.setDailyTarget(value.toInt());
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '권장: 7-9시간',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 하루 시작 시간 설정
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          '하루 시작 시간',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '야간 근무자를 위해 하루의 시작 시간을 설정할 수 있습니다.\n예: 오전 6시로 설정하면, 6시 이전은 전날로 계산됩니다.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${settingsProvider.dayStartHour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: settingsProvider.dayStartHour.toDouble(),
                      min: 0,
                      max: 23,
                      divisions: 23,
                      label: '${settingsProvider.dayStartHour.toString().padLeft(2, '0')}:00',
                      onChanged: (value) async {
                        await settingsProvider.setDayStartHour(value.toInt());
                        // 날짜 계산이 변경되므로 관련 Provider들 갱신
                        if (mounted) {
                          final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
                          final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
                          sleepProvider.notifyListeners();
                          scheduleProvider.notifyListeners();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildQuickTimeButton('자정 (0시)', 0, settingsProvider),
                        _buildQuickTimeButton('새벽 3시', 3, settingsProvider),
                        _buildQuickTimeButton('새벽 6시', 6, settingsProvider),
                        _buildQuickTimeButton('오전 9시', 9, settingsProvider),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 현재 설정 정보
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingRow('목표 수면시간', '${settingsProvider.dailyTargetHours}시간'),
                    _buildSettingRow('하루 시작 시간', '${settingsProvider.dayStartHour.toString().padLeft(2, '0')}:00'),
                    if (settingsProvider.dayStartHour != 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '⚠️ 하루 시작 시간이 변경되어 날짜 계산이 조정됩니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTimeButton(String label, int hour, SettingsProvider provider) {
    final isSelected = provider.dayStartHour == hour;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        if (selected) {
          await provider.setDayStartHour(hour);
          if (mounted) {
            Provider.of<SleepProvider>(context, listen: false).notifyListeners();
            Provider.of<ScheduleProvider>(context, listen: false).notifyListeners();
          }
        }
      },
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

