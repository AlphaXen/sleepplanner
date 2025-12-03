import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/env_provider.dart';
import 'lux_noise_detail_screen.dart';
import 'daily_stats_screen.dart';

class LightGuideScreen extends StatelessWidget {
  const LightGuideScreen({super.key});

  List<PieChartSectionData> _buildPieData(Map<int, int> stats) {
    final tot = stats.values.fold(0, (a, b) => a + b);
    if (tot == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey,
          title: "데이터 없음",
          radius: 45,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
      ];
    }

    return [
      PieChartSectionData(
        value: stats[0]!.toDouble(),
        color: Colors.green,
        radius: 45,
        title: "좋음\n${(stats[0]! * 100 / tot).toStringAsFixed(0)}%",
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: stats[1]!.toDouble(),
        color: Colors.orange,
        radius: 45,
        title: "주의\n${(stats[1]! * 100 / tot).toStringAsFixed(0)}%",
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: stats[2]!.toDouble(),
        color: Colors.red,
        radius: 45,
        title: "방해\n${(stats[2]! * 100 / tot).toStringAsFixed(0)}%",
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "빛·소음 노출 가이드",
          style: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      body: Consumer<EnvProvider>(
        builder: (context, provider, _) {
          final latest =
              provider.samples.isNotEmpty ? provider.samples.last : null;
          final stats = provider.getDangerStats();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 서비스 토글
              Card(
                child: SwitchListTile(
                  value: provider.serviceRunning,
                  title: const Text(
                    "가이드 활성화",
                    style: TextStyle(fontFamily: 'Roboto'),
                  ),
                  subtitle: const Text(
                    "5초마다 측정",
                    style: TextStyle(fontFamily: 'Roboto'),
                  ),
                  onChanged: (v) =>
                      v ? provider.startService() : provider.stopService(),
                ),
              ),

              const SizedBox(height: 16),

              // 최신 센서 값
              if (latest != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "밝기: ${latest.lux.toStringAsFixed(1)} lux",
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      Text(
                        "소음: ${latest.noiseDb.toStringAsFixed(1)} dB",
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              Text(
                provider.message,
                style: const TextStyle(fontFamily: 'Roboto'),
              ),

              const SizedBox(height: 20),

              // 파이 차트
              const Text(
                "환경 방해도 분석 (최근 10분)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sections: _buildPieData(stats),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 기준 설명
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "환경 기준",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "• 좋음: 밝기 ≤ 50 lux, 소음 ≤ 40 dB",
                      style: TextStyle(fontFamily: 'Roboto'),
                    ),
                    Text(
                      "• 주의: 밝기 50~80 lux, 소음 40~50 dB",
                      style: TextStyle(fontFamily: 'Roboto'),
                    ),
                    Text(
                      "• 방해: 밝기 ≥ 80 lux, 소음 ≥ 50 dB",
                      style: TextStyle(fontFamily: 'Roboto'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 상세 그래프 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LuxNoiseDetailScreen(
                        samples: provider.samples,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "밝기·소음 상세 그래프",
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
              ),

              const SizedBox(height: 20),

              // 오늘의 통계 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyStatsScreen(log: provider.localDb),
                    ),
                  );
                },
                child: const Text(
                  "📊 오늘의 통계 보기",
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
              ),

              const SizedBox(height: 20),

              // 데이터 삭제 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await provider.clearDb();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "로컬 DB 삭제됨",
                          style: TextStyle(fontFamily: 'Roboto'),
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  "❌ 로컬 데이터 삭제",
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
