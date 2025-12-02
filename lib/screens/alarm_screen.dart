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
        title: const Text('Alarms'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Alarm Info',
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
                    'No alarms set',
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
        label: const Text('Add Alarm'),
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
            Text('Alarm Information'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Automatic Scheduling',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your alarms are now scheduled to ring automatically at the specified time.',
            ),
            SizedBox(height: 16),
            Text(
              '🔔 How it works:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Toggle ON to enable alarm\n'
                '• Notification will appear at alarm time\n'
                '• Tap notification to play alarm sound\n'
                '• Use "Test Sound" to preview alarm\n'
                '• Repeat days work automatically'),
            SizedBox(height: 16),
            Text(
              '⚠️ Important:',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            SizedBox(height: 8),
            Text('• Keep app permissions enabled\n'
                '• Don\'t clear app from recent apps\n'
                '• Check battery optimization settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
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
          title: const Text('Add New Alarm'),
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
                    labelText: 'Label',
                    hintText: 'e.g., Wake up',
                    prefixIcon: Icon(Icons.label),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => label = value,
                ),
                const SizedBox(height: 16),
                // Repeat Days
                const Text(
                  'Repeat',
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final alarm = AlarmModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  time: selectedTime,
                  label: label.isEmpty ? 'Alarm' : label,
                  repeatDays: selectedDays,
                );
                Provider.of<AlarmProvider>(context, listen: false)
                    .addAlarm(alarm);
                Navigator.pop(context);
              },
              child: const Text('Save'),
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
                            content: Text('Alarm sound playing (10 seconds)'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Test Sound'),
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
