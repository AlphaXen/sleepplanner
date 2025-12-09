import 'package:flutter/material.dart';
import 'ai_sleep_analysis_screen.dart';
import 'shift_worker_dashboard_screen.dart';

/// AI 분석 및 야간 근무 기능을 통합한 화면
class IntegratedSleepManagementScreen extends StatefulWidget {
  const IntegratedSleepManagementScreen({super.key});

  @override
  State<IntegratedSleepManagementScreen> createState() =>
      _IntegratedSleepManagementScreenState();
}

class _IntegratedSleepManagementScreenState
    extends State<IntegratedSleepManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 분석 & 적응형 수면 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.psychology),
              text: 'AI 분석',
            ),
            Tab(
              icon: Icon(Icons.work_history),
              text: '야간 근무',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AISleepAnalysisScreen(hideAppBar: true),
          ShiftWorkerDashboardScreen(hideAppBar: true),
        ],
      ),
    );
  }
}

