import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'providers/sleep_provider.dart';
import 'providers/auto_reply_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/alarm_provider.dart';
import 'providers/music_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/env_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/onboarding_service.dart';
import 'utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone for alarm scheduling
  _initializeTimezone();

  // Initialize Firebase
  await _initializeFirebase();

  runApp(const SleepPlannerApp());
}

void _initializeTimezone() {
  try {
    tz.initializeTimeZones();
    AppLogger.info('Timezone initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize timezone', e);
  }
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    AppLogger.info('Firebase initialized successfully');
  } catch (e) {
    AppLogger.warn(
        'Firebase initialization failed. App will continue without Firebase. $e');
  }
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
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => EnvProvider()),
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
            themeMode: theme.mode,
            home: const _HomeRouter(),
          );
        },
      ),
    );
  }
}

class _HomeRouter extends StatelessWidget {
  const _HomeRouter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingService.isOnboardingCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isOnboardingCompleted = snapshot.data ?? false;

        if (isOnboardingCompleted) {
          return const HomeScreen();
        } else {
          return OnboardingScreen(
            onCompleted: () async {
              await OnboardingService.markOnboardingAsCompleted();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            },
          );
        }
      },
    );
  }
}