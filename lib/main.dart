import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/sleep_provider.dart';
import 'providers/auto_reply_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(); // firebase_options.dart 쓰면 옵션 추가
  } catch (e, st) {
    // If native Firebase config is missing (google-services.json / plist),
    // initialization will fail on mobile. Catch and continue so the app
    // can still run without Firebase during development.
    // Log the error for debugging.
    // ignore: avoid_print
    print('Firebase initialization failed: $e');
    // ignore: avoid_print
    print(st);
  }

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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Sleep Planner',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF283593),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF283593),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: theme.mode, // 🌗 Dark/Light Mode here
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
