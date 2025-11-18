import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../models/sleep_entry.dart';
import 'stats_screen.dart';
import 'shift_input_screen.dart';
import 'auto_reply_settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SleepProvider>(context);
    final duration = provider.todaySleepDuration;
    final progress = provider.todayProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Planner'),
        actions: [
          // 🔥 Auto Reply Settings Screen 이동 버튼
          IconButton(
            icon: const Icon(Icons.message_outlined),
            tooltip: 'Auto Reply Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AutoReplySettingsScreen()),
              );
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
          IconButton(
            icon: const Icon(Icons.lightbulb),
            tooltip: 'Daily Plan',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShiftInputScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTodaySummary(
                context, duration, progress, provider.dailyTargetHours),
            const SizedBox(height: 16),
            _buildTargetEditor(context, provider),
            const SizedBox(height: 16),
            _buildEntryList(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Sleep'),
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
                  Text('Today Sleep',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text('$h h $m m / $targetHours h'),
                  const SizedBox(height: 8),
                  Text(
                    progress >= 1
                        ? '목표 수면시간을 달성했습니다! 😴'
                        : '오늘 목표까지 조금 더 잘 수 있습니다.',
                  ),
                ],
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
        const Text('Daily Target (hours):'),
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
    return Expanded(
      child: Consumer<SleepProvider>(
        builder: (context, provider, _) {
          if (provider.entries.isEmpty) {
            return const Center(
              child: Text(
                'No sleep records yet.\nTap + to add.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: provider.entries.length,
            itemBuilder: (context, index) {
              final e = provider.entries[index];
              return ListTile(
                leading:
                    Icon(e.isNightShift ? Icons.dark_mode : Icons.wb_sunny),
                title: Text(
                  '${_formatDateTime(e.sleepTime)} → ${_formatDateTime(e.wakeTime)}',
                ),
                subtitle: Text('Duration: ${e.formattedDuration}'),
              );
            },
          );
        },
      ),
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
              title: const Text('Add Sleep Entry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDateTimePicker(
                    context: context,
                    label: 'Sleep Time',
                    value: sleepTime,
                    onTap: () async {
                      final result = await _pickDateTime(context);
                      if (result != null) setState(() => sleepTime = result);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDateTimePicker(
                    context: context,
                    label: 'Wake Time',
                    value: wakeTime,
                    onTap: () async {
                      final result = await _pickDateTime(context);
                      if (result != null) setState(() => wakeTime = result);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Night shift sleep?'),
                      const Spacer(),
                      Switch(
                        value: isNightShift,
                        onChanged: (v) => setState(() => isNightShift = v),
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
                    provider.addEntry(
                      SleepEntry(
                        sleepTime: sleepTime!,
                        wakeTime: wakeTime!,
                        isNightShift: isNightShift,
                      ),
                    );
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
}
