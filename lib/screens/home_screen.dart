import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../models/sleep_entry.dart';
import 'shift_settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sleepProvider = Provider.of<SleepProvider>(context);
    final todayDuration = sleepProvider.todaySleepDuration;
    final progress = sleepProvider.todayProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.nightlight_round),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShiftSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTodaySummary(context, todayDuration, progress, sleepProvider.dailyTargetHours),
            const SizedBox(height: 24),
            _buildEntryList(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _showAddEntryDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Sleep'),
      ),
    );
  }

  Widget _buildTodaySummary(
      BuildContext context, Duration duration, double progress, int targetHours) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
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
                  Text(
                    'Today Sleep',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('$hours h $minutes m / $targetHours h'),
                  const SizedBox(height: 8),
                  Text(
                    progress >= 1
                        ? 'Target reached! 😴'
                        : 'Keep going to reach your goal.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList(BuildContext context) {
    return Expanded(
      child: Consumer<SleepProvider>(
        builder: (context, provider, _) {
          if (provider.entries.isEmpty) {
            return const Center(
              child: Text('No sleep records yet. Tap + to add.', textAlign: TextAlign.center),
            );
          }
          return ListView.builder(
            itemCount: provider.entries.length,
            itemBuilder: (context, index) {
              final entry = provider.entries[index];
              return ListTile(
                leading: Icon(
                  entry.isNightShift ? Icons.dark_mode : Icons.wb_sunny,
                ),
                title: Text(
                  '${_formatTime(entry.sleepTime)} → ${_formatTime(entry.wakeTime)}',
                ),
                subtitle: Text('Duration: ${entry.formattedDuration}'),
              );
            },
          );
        },
      ),
    );
  }

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
              title: const Text('Add Sleep Entry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDateTimePicker(
                    context: context,
                    label: 'Sleep Time',
                    value: sleepTime,
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
                      if (time == null) return;
                      if (!context.mounted) return;
                      setState(() {
                        sleepTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDateTimePicker(
                    context: context,
                    label: 'Wake Time',
                    value: wakeTime,
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
                      if (time == null) return;
                      if (!context.mounted) return;
                      setState(() {
                        wakeTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Night shift sleep?'),
                      const Spacer(),
                      Switch(
                        value: isNightShift,
                        onChanged: (v) {
                          setState(() {
                            isNightShift = v;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (sleepTime == null || wakeTime == null) return;
                    if (wakeTime!.isBefore(sleepTime!)) return;
                    final provider =
                        Provider.of<SleepProvider>(context, listen: false);
                    provider.addEntry(SleepEntry(
                      sleepTime: sleepTime!,
                      wakeTime: wakeTime!,
                      isNightShift: isNightShift,
                    ));
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateTimePicker({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value == null ? 'Select...' : _formatTime(value)),
      trailing: const Icon(Icons.schedule),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} '
        '${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}
