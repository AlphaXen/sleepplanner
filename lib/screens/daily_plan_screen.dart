import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../models/daily_plan.dart';

class DailyPlanScreen extends StatelessWidget {
  const DailyPlanScreen({super.key});

  String _fmt(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SleepProvider>(context);
    final plan = provider.lastDailyPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Sleep Plan"),
      ),
      body: plan == null
          ? const Center(
              child: Text(
                "아직 Daily Plan 이 없습니다.\n근무 정보를 입력해 계산하세요.",
                textAlign: TextAlign.center,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMainSleepCard(plan),
                  const SizedBox(height: 16),
                  _buildCaffeineCard(plan),
                  const SizedBox(height: 16),
                  _buildWinddownCard(plan),
                  const SizedBox(height: 16),
                  _buildLightCard(plan),
                  const SizedBox(height: 16),
                  _buildNotesCard(plan),
                ],
              ),
            ),
    );
  }

  Widget _buildMainSleepCard(DailyPlan plan) {
    final dur = plan.mainSleepEnd.difference(plan.mainSleepStart);
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🛌 메인 수면 시간",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Start: ${_fmt(plan.mainSleepStart)}",
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
            Text(
              "End:   ${_fmt(plan.mainSleepEnd)}",
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 8),
            Text(
              "Duration: ${h}h ${m}m",
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaffeineCard(DailyPlan plan) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "☕ 카페인 컷오프",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "카페인 제한 시작 시간: ${_fmt(plan.caffeineCutoff)}",
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinddownCard(DailyPlan plan) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🌙 취침 준비 시작 시간",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Wind-down 시작: ${_fmt(plan.winddownStart)}",
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightCard(DailyPlan plan) {
    return Card(
      color: Colors.yellow.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "💡 빛 노출 전략",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 12),
            ...plan.lightPlan.entries.map(
              (e) => Text(
                "- ${e.key}: ${e.value}",
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(DailyPlan plan) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📝 Notes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 12),
            ...plan.notes.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "- $n",
                  style: const TextStyle(fontFamily: 'Roboto'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
