import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'providers/sleep_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const SleepPlannerApp());
}

class SleepPlannerApp extends StatelessWidget {
  const SleepPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SleepProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sleep Planner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF283593),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
