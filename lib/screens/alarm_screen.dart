import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alarm_provider.dart';
import '../models/alarm_model.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '알람 정보',
            onPressed: () => _showAlarmInfo(context),
          ),
        ],
      ),
      body: Consumer<AlarmProvider>(
        builder: (context, alarmProvider, child) {
          final alarms = alarmProvider.alarms;

          if (alarms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '설정된 알람이 없습니다',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alarms.length,
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              return _AlarmCard(alarm: alarm);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAlarmDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('알람 추가'),
      ),
    );
  }

  void _showAlarmInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('알람 정보'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ 자동 스케줄링',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '알람이 지정된 시간에 자동으로 울리도록 스케줄됩니다.',
            ),
            SizedBox(height: 16),
            Text(
              '🔔 사용 방법:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• 토글을 켜서 알람 활성화\n'
                '• 알람 시간에 알림이 표시됩니다\n'
                '• 알림을 탭하여 알람 소리 재생\n'
                '• "소리 테스트"로 알람 미리보기\n'
                '• 반복 요일이 자동으로 작동합니다'),
            SizedBox(height: 16),
            Text(
              '⚠️ 중요 사항:',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            SizedBox(height: 8),
            Text('• 앱 권한을 활성화 상태로 유지하세요\n'
                '• 최근 앱 목록에서 앱을 삭제하지 마세요\n'
                '• 배터리 최적화 설정을 확인하세요'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인!'),
          ),
        ],
      ),
    );
  }

  void _showAddAlarmDialog(BuildContext context) {
    TimeOfDay selectedTime = TimeOfDay.now();
    String label = '';
    final List<int> selectedDays = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('새 알람 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Picker
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    selectedTime.format(context),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Label Input
                TextField(
                  decoration: const InputDecoration(
                    labelText: '이름',
                    hintText: '예: 기상 알람',
                    prefixIcon: Icon(Icons.label),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => label = value,
                ),
                const SizedBox(height: 16),
                // Repeat Days
                const Text(
                  '반복',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 0; i < 7; i++)
                      FilterChip(
                        label: Text(['S', 'M', 'T', 'W', 'T', 'F', 'S'][i]),
                        selected: selectedDays.contains(i),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedDays.add(i);
                            } else {
                              selectedDays.remove(i);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final alarm = AlarmModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  time: selectedTime,
                  label: label.isEmpty ? '알람' : label,
                  repeatDays: selectedDays,
                );
                Provider.of<AlarmProvider>(context, listen: false)
                    .addAlarm(alarm);
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final AlarmModel alarm;

  const _AlarmCard({required this.alarm});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: alarm.isEnabled
                ? [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ]
                : [Colors.grey.shade200, Colors.grey.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Text(
                alarm.formattedTime,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: alarm.isEnabled ? Colors.black87 : Colors.grey,
                ),
              ),
              const Spacer(),
              Switch(
                value: alarm.isEnabled,
                onChanged: (value) {
                  Provider.of<AlarmProvider>(context, listen: false)
                      .toggleAlarm(alarm.id);
                },
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.label,
                      size: 16,
                      color: alarm.isEnabled ? Colors.black54 : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alarm.label,
                      style: TextStyle(
                        fontSize: 16,
                        color: alarm.isEnabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: alarm.isEnabled ? Colors.black54 : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alarm.repeatText,
                      style: TextStyle(
                        fontSize: 14,
                        color: alarm.isEnabled ? Colors.black54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Test alarm sound button
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final provider = Provider.of<AlarmProvider>(
                          context,
                          listen: false,
                        );
                        provider.playAlarmSound(alarm.soundPath);
                        // Auto-stop after 10 seconds
                        Future.delayed(const Duration(seconds: 10), () {
                          provider.stopAlarmSound();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('알람 소리 재생 중 (10초)'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('소리 테스트'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Provider.of<AlarmProvider>(context, listen: false)
                            .stopAlarmSound();
                      },
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('Stop'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              Provider.of<AlarmProvider>(context, listen: false)
                  .deleteAlarm(alarm.id);
            },
          ),
        ),
      ),
    );
  }
}
