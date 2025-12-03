import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/env_sample.dart';

class LuxNoiseDetailScreen extends StatelessWidget {
  final List<EnvSample> samples;

  const LuxNoiseDetailScreen({super.key, required this.samples});

  static const int keepSeconds = 600;

  List<EnvSample> get _trim {
    final cutoff =
        DateTime.now().subtract(const Duration(seconds: keepSeconds));
    return samples.where((s) => s.time.isAfter(cutoff)).toList();
  }

  List<FlSpot> _lux(List<EnvSample> s) {
    final base = DateTime.now().subtract(const Duration(seconds: keepSeconds));
    return s
        .map(
            (e) => FlSpot(e.time.difference(base).inMilliseconds / 1000, e.lux))
        .toList();
  }

  List<FlSpot> _noise(List<EnvSample> s) {
    final base = DateTime.now().subtract(const Duration(seconds: keepSeconds));
    return s
        .map((e) =>
            FlSpot(e.time.difference(base).inMilliseconds / 1000, e.noiseDb))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = _trim;
    final lux = _lux(data);
    final noise = _noise(data);

    double minLux = lux.isEmpty ? 0 : lux.map((e) => e.y).reduce(min);
    double maxLux = lux.isEmpty ? 100 : lux.map((e) => e.y).reduce(max);

    double minNoise = noise.isEmpty ? 20 : noise.map((e) => e.y).reduce(min);
    double maxNoise = noise.isEmpty ? 60 : noise.map((e) => e.y).reduce(max);

    if (maxLux - minLux < 30) maxLux = minLux + 30;
    if (maxNoise - minNoise < 20) maxNoise = minNoise + 20;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "상세 그래프 (최근 10분)",
          style: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "밝기(Lux)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                clipData: const FlClipData.all(),
                minX: 0,
                maxX: 600,
                minY: minLux,
                maxY: maxLux,
                lineBarsData: [
                  LineChartBarData(
                    spots: lux,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  )
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxLux - minLux) / 4,
                      getTitlesWidget: (v, meta) => Text(
                        "${v.toInt()}",
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 120,
                      reservedSize: 30,
                      getTitlesWidget: (v, meta) => Text(
                        "${(v ~/ 60)}m",
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "소음(dB)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                clipData: const FlClipData.all(),
                minX: 0,
                maxX: 600,
                minY: minNoise,
                maxY: maxNoise,
                lineBarsData: [
                  LineChartBarData(
                    spots: noise,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  )
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxNoise - minNoise) / 4,
                      getTitlesWidget: (v, meta) => Text(
                        "${v.toInt()}",
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 120,
                      reservedSize: 30,
                      getTitlesWidget: (v, meta) => Text(
                        "${(v ~/ 60)}m",
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
