import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sleep_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SleepProvider>(context);
    final data = provider.last7DaysSleepHours;

    final spots = <FlSpot>[];
    final labels = <String>[];
    int index = 0;
    for (final entry in data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      index++;
      spots.add(FlSpot(index.toDouble(), entry.value.toDouble()));
      labels.add('${entry.key.month}/${entry.key.day}');
    }

    final todayProgress = provider.todayProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Stats & Graph'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPieCard(context, todayProgress),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i <= 0 || i > labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  labels[i - 1],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieCard(BuildContext context, double progress) {
    final complete = (progress * 100).clamp(0, 100).toDouble();
    final remaining = 100.0 - complete;

    return Card(
      child: SizedBox(
        height: 220,
        child: Row(
          children: [
            SizedBox(
              width: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: complete,
                      title: '${complete.toStringAsFixed(0)}%',
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: remaining,
                      title: '',
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Today\'s Sleep Goal Progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Completed: ${complete.toStringAsFixed(1)} %'),
                    Text('Remaining: ${remaining.toStringAsFixed(1)} %'),
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
