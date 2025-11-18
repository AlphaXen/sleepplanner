import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sleep_provider.dart';
import 'providers/auto_reply_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const SleepPlannerApp());
}

class SleepPlannerApp extends StatelessWidget {
  const SleepPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SleepProvider()),
        ChangeNotifierProvider(create: (_) => AutoReplyProvider()),
      ],
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
