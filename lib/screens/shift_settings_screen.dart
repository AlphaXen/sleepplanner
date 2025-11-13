import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';

class ShiftSettingsScreen extends StatelessWidget {
  const ShiftSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SleepProvider>(context);

    final targetController =
        TextEditingController(text: provider.dailyTargetHours.toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift & Health Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('I am a night-shift / rotating worker'),
              subtitle: const Text('Use night-friendly tips & layout'),
              value: provider.isNightShiftWorker,
              onChanged: (v) => provider.setNightShiftWorker(v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily sleep target (hours)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                final hours = int.tryParse(value);
                if (hours != null && hours > 0 && hours <= 14) {
                  provider.setDailyTarget(hours);
                }
              },
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Health Tips for Night Workers',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.brightness_3),
                      title: Text('Keep the bedroom dark and cool'),
                      subtitle: Text(
                          'Use blackout curtains, eye masks, and earplugs when you sleep in the daytime.'),
                    ),
                    ListTile(
                      leading: Icon(Icons.coffee),
                      title: Text('Limit caffeine before sleep'),
                      subtitle: Text(
                          'Avoid coffee, tea, and energy drinks for at least 4–6 hours before your planned sleep time.'),
                    ),
                    ListTile(
                      leading: Icon(Icons.phone_iphone),
                      title: Text('Reduce phone and screen time'),
                      subtitle: Text(
                          'Blue light from screens can delay your sleep. Use night mode and put the phone away 30 minutes before sleep.'),
                    ),
                    ListTile(
                      leading: Icon(Icons.directions_walk),
                      title: Text('Short walk after work'),
                      subtitle: Text(
                          'A short walk and stretching after night work can relax your body and improve sleep.'),
                    ),
                    ListTile(
                      leading: Icon(Icons.local_hospital),
                      title: Text('Watch your health'),
                      subtitle: Text(
                          'Long-term night work can increase health risks. Check your blood pressure, weight, and mood regularly.'),
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
}
