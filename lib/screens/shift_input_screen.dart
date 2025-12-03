import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../models/shift_info.dart';
import 'daily_plan_screen.dart';

class ShiftInputScreen extends StatefulWidget {
  const ShiftInputScreen({super.key});

  @override
  State<ShiftInputScreen> createState() => _ShiftInputScreenState();
}

class _ShiftInputScreenState extends State<ShiftInputScreen> {
  ShiftType _type = ShiftType.day;
  DateTime? _shiftStart;
  DateTime? _shiftEnd;
  DateTime? _preferredMid;

  Future<DateTime?> _pickDateTime(BuildContext context, {String? help}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: help,
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      helpText: help,
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    final provider = Provider.of<SleepProvider>(context, listen: false);

    ShiftInfo shift;
    if (_type == ShiftType.off) {
      if (_preferredMid == null) return;
      shift = ShiftInfo.off(preferredMid: _preferredMid);
    } else {
      if (_shiftStart == null || _shiftEnd == null) return;
      if (_type == ShiftType.day) {
        shift = ShiftInfo.day(
          shiftStart: _shiftStart,
          shiftEnd: _shiftEnd,
        );
      } else {
        shift = ShiftInfo.night(
          shiftStart: _shiftStart,
          shiftEnd: _shiftEnd,
        );
      }
    }

    provider.computeTodayPlanForShift(shift);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DailyPlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Work Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<ShiftType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Select Shift Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ShiftType.day,
                  child: Text('Day Shift (DAY)'),
                ),
                DropdownMenuItem(
                  value: ShiftType.night,
                  child: Text('Night Shift (NIGHT)'),
                ),
                DropdownMenuItem(
                  value: ShiftType.off,
                  child: Text('Day Off (OFF)'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _type = v);
              },
            ),
            const SizedBox(height: 16),
            if (_type != ShiftType.off) ...[
              _buildTile(
                title: 'Shift Start Time',
                value: _shiftStart,
                onTap: () async {
                  final dt = await _pickDateTime(
                    context,
                    help: 'Select shift start time',
                  );
                  if (dt != null) setState(() => _shiftStart = dt);
                },
              ),
              _buildTile(
                title: 'Shift End Time',
                value: _shiftEnd,
                onTap: () async {
                  final dt = await _pickDateTime(
                    context,
                    help: 'Select shift end time',
                  );
                  if (dt != null) setState(() => _shiftEnd = dt);
                },
              ),
            ] else ...[
              _buildTile(
                title: 'Preferred Mid-sleep Time (Day Off)',
                value: _preferredMid,
                onTap: () async {
                  final dt = await _pickDateTime(
                    context,
                    help: 'Select mid-sleep time',
                  );
                  if (dt != null) setState(() => _preferredMid = dt);
                },
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Calculate Daily Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    String subtitle;
    if (value == null) {
      subtitle = 'Select...';
    } else {
      subtitle =
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
          '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.schedule),
      onTap: onTap,
    );
  }
}
