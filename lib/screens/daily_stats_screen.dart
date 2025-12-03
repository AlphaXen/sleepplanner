import 'dart:math';
import 'package:flutter/material.dart';
import '../models/env_sample.dart';

class DailyStatsScreen extends StatelessWidget {
  final List<EnvSample> log;

  const DailyStatsScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    if (log.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "오늘의 통계",
            style: TextStyle(fontFamily: 'Roboto'),
          ),
        ),
        body: const Center(
          child: Text(
            "기록이 없습니다.",
            style: TextStyle(fontFamily: 'Roboto'),
          ),
        ),
      );
    }

    final avgLux = log.map((e) => e.lux).reduce((a, b) => a + b) / log.length;
    final avgNoise =
        log.map((e) => e.noiseDb).reduce((a, b) => a + b) / log.length;

    final maxLux = log.map((e) => e.lux).reduce(max);
    final maxNoise = log.map((e) => e.noiseDb).reduce(max);

    int good = 0, warn = 0, bad = 0;

    for (var s in log) {
      int l = s.lux <= 50 ? 0 : (s.lux < 80 ? 1 : 2);
      int n = s.noiseDb <= 40 ? 0 : (s.noiseDb < 50 ? 1 : 2);
      int d = max(l, n);

      if (d == 0) good++;
      if (d == 1) warn++;
      if (d == 2) bad++;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "오늘의 환경 통계",
          style: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "🔥 오늘 측정 수: ${log.length}",
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "📌 평균 밝기: ${avgLux.toStringAsFixed(1)} lux",
            style: const TextStyle(
              fontSize: 17,
              fontFamily: 'Roboto',
            ),
          ),
          Text(
            "📌 최대 밝기: ${maxLux.toStringAsFixed(1)} lux",
            style: const TextStyle(
              fontSize: 17,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "🎧 평균 소음: ${avgNoise.toStringAsFixed(1)} dB",
            style: const TextStyle(
              fontSize: 17,
              fontFamily: 'Roboto',
            ),
          ),
          Text(
            "🎧 최대 소음: ${maxNoise.toStringAsFixed(1)} dB",
            style: const TextStyle(
              fontSize: 17,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "👌 좋음: $good 회",
            style: const TextStyle(
              fontSize: 17,
              color: Colors.green,
              fontFamily: 'Roboto',
            ),
          ),
          Text(
            "⚠️ 주의: $warn 회",
            style: const TextStyle(
              fontSize: 17,
              color: Colors.orange,
              fontFamily: 'Roboto',
            ),
          ),
          Text(
            "⛔ 방해: $bad 회",
            style: const TextStyle(
              fontSize: 17,
              color: Colors.red,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }
}
