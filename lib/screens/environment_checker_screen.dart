import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('light_guide_channel');

class EnvSample {
  final DateTime time;
  final double lux;
  final double noiseDb;

  EnvSample(this.time, this.lux, this.noiseDb);

  Map<String, dynamic> toJson() => {
        "t": time.millisecondsSinceEpoch,
        "lux": lux,
        "db": noiseDb,
      };

  static EnvSample fromJson(Map<String, dynamic> m) {
    return EnvSample(
      DateTime.fromMillisecondsSinceEpoch(m["t"]),
      (m["lux"] as num).toDouble(),
      (m["db"] as num).toDouble(),
    );
  }
}

/// =====================================================================
///                    ENVIRONMENT CHECKER SCREEN
/// =====================================================================
class EnvironmentCheckerScreen extends StatefulWidget {
  const EnvironmentCheckerScreen({super.key});

  @override
  State<EnvironmentCheckerScreen> createState() =>
      _EnvironmentCheckerScreenState();
}

class _EnvironmentCheckerScreenState extends State<EnvironmentCheckerScreen> {
  bool _serviceRunning = false;
  String _message = "Service is off.";
  List<EnvSample> _samples = [];
  List<EnvSample> _localDb = [];
  Timer? _poller;

  static const int keepSeconds = 600; // Last 10 minutes

  @override
  void initState() {
    super.initState();
    _reqPerms();
    _loadLocalDb();
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _reqPerms() async {
    await Permission.microphone.request();
    await Permission.notification.request();
  }

  Future<void> _loadLocalDb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("env_history");
    if (raw == null) return;

    final list = jsonDecode(raw) as List;
    setState(() {
      _localDb = list.map((e) => EnvSample.fromJson(e)).toList();
    });
  }

  Future<void> _saveLocalDb() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _localDb.map((e) => e.toJson()).toList();
    prefs.setString("env_history", jsonEncode(list));
  }

  Future<void> _clearDb() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("env_history");
    setState(() => _localDb.clear());
  }

  Future<void> _startService() async {
    try {
      await _channel.invokeMethod("startLightService");
      setState(() {
        _serviceRunning = true;
        _message = "Measuring in real-time...";
      });
      _startPolling();
    } catch (e) {
      setState(() => _message = "Failed to start service: $e");
    }
  }

  Future<void> _stopService() async {
    await _channel.invokeMethod("stopLightService");
    _poller?.cancel();
    setState(() {
      _serviceRunning = false;
      _message = "Service stopped.";
      _samples.clear();
    });
  }

  void _startPolling() {
    _poller?.cancel();

    _poller = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final raw = await _channel.invokeMethod("getEnvSamples");
        final data = (raw as List).map((e) {
          final m = Map<String, dynamic>.from(e);
          return EnvSample(
            DateTime.fromMillisecondsSinceEpoch(m["timestampMillis"]),
            (m["lux"] as num).toDouble(),
            (m["noiseDb"] as num).toDouble(),
          );
        }).toList();

        if (data.isEmpty) return;

        setState(() {
          _samples.addAll(data);

          final cutoff =
              DateTime.now().subtract(const Duration(seconds: keepSeconds));
          _samples = _samples.where((s) => s.time.isAfter(cutoff)).toList();

          _localDb.addAll(data);

          final dayCutoff =
              DateTime.now().subtract(const Duration(hours: 24));
          _localDb = _localDb.where((s) => s.time.isAfter(dayCutoff)).toList();
        });

        _saveLocalDb();
      } catch (_) {}
    });
  }

  int danger(double lux, double db) {
    int l = lux <= 50 ? 0 : (lux < 80 ? 1 : 2);
    int n = db <= 40 ? 0 : (db < 50 ? 1 : 2);
    return max(l, n);
  }

  List<PieChartSectionData> _pie() {
    final map = {0: 0, 1: 0, 2: 0};
    for (final s in _samples) {
      map[danger(s.lux, s.noiseDb)] = map[danger(s.lux, s.noiseDb)]! + 1;
    }

    final tot = map.values.fold(0, (a, b) => a + b);
    if (tot == 0) {
      return [
        PieChartSectionData(
            value: 1, color: Colors.grey, title: "No Data", radius: 45)
      ];
    }

    return [
      PieChartSectionData(
          value: map[0]!.toDouble(),
          color: Colors.green,
          radius: 45,
          title: "Good\n${(map[0]! * 100 / tot).toStringAsFixed(0)}%"),
      PieChartSectionData(
          value: map[1]!.toDouble(),
          color: Colors.orange,
          radius: 45,
          title: "Caution\n${(map[1]! * 100 / tot).toStringAsFixed(0)}%"),
      PieChartSectionData(
          value: map[2]!.toDouble(),
          color: Colors.red,
          radius: 45,
          title: "Poor\n${(map[2]! * 100 / tot).toStringAsFixed(0)}%"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final latest = _samples.isNotEmpty ? _samples.last : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Environment Checker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Daily Statistics',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DailyStatsPage(log: _localDb)));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Toggle Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _serviceRunning
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _serviceRunning
                                ? Icons.sensors_rounded
                                : Icons.sensors_off_rounded,
                            size: 32,
                            color: _serviceRunning ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Environment Monitor',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Measure every 5 seconds',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _serviceRunning,
                          onChanged: (v) =>
                              v ? _startService() : _stopService(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Current Reading Card
                if (latest != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Reading',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildReadingTile(
                                  icon: Icons.wb_sunny_rounded,
                                  label: 'Light',
                                  value: '${latest.lux.toStringAsFixed(1)} lux',
                                  color: const Color(0xFFf5a623),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildReadingTile(
                                  icon: Icons.volume_up_rounded,
                                  label: 'Noise',
                                  value:
                                      '${latest.noiseDb.toStringAsFixed(1)} dB',
                                  color: const Color(0xFF4a90d9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                if (latest == null && _serviceRunning)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(_message, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Analysis Chart Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sleep Environment Analysis (Last 10 min)',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                                centerSpaceRadius: 40, sections: _pie()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Environment Standards Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Environment Standards',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStandardRow(
                            'Good', 'Light ≤ 50 lux, Noise ≤ 40 dB',
                            Colors.green),
                        const SizedBox(height: 8),
                        _buildStandardRow(
                            'Caution', 'Light 50-80 lux, Noise 40-50 dB',
                            Colors.orange),
                        const SizedBox(height: 8),
                        _buildStandardRow(
                            'Poor', 'Light ≥ 80 lux, Noise ≥ 50 dB',
                            Colors.red),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LuxNoiseDetailPage(samples: _samples),
                            ),
                          );
                        },
                        icon: const Icon(Icons.show_chart),
                        label: const Text('Detail Graphs'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Clear Data'),
                              content: const Text(
                                  'Are you sure you want to delete all local data?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _clearDb();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Local data deleted')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear Data'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardRow(String level, String desc, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(
          '$level: ',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Expanded(child: Text(desc)),
      ],
    );
  }
}

/// =====================================================================
///                   DETAIL GRAPH PAGE (10 minutes)
/// =====================================================================
class LuxNoiseDetailPage extends StatelessWidget {
  final List<EnvSample> samples;

  const LuxNoiseDetailPage({super.key, required this.samples});

  static const int keepSeconds = 600;

  List<EnvSample> get _trim {
    final cutoff =
        DateTime.now().subtract(const Duration(seconds: keepSeconds));
    return samples.where((s) => s.time.isAfter(cutoff)).toList();
  }

  List<FlSpot> _lux(List<EnvSample> s) {
    final base =
        DateTime.now().subtract(const Duration(seconds: keepSeconds));
    return s
        .map((e) =>
            FlSpot(e.time.difference(base).inMilliseconds / 1000, e.lux))
        .toList();
  }

  List<FlSpot> _noise(List<EnvSample> s) {
    final base =
        DateTime.now().subtract(const Duration(seconds: keepSeconds));
    return s
        .map((e) =>
            FlSpot(e.time.difference(base).inMilliseconds / 1000, e.noiseDb))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _trim;
    final luxSpots = _lux(data);
    final noiseSpots = _noise(data);

    // Calculate stats
    double minLux = luxSpots.isEmpty ? 0 : luxSpots.map((e) => e.y).reduce(min);
    double maxLux = luxSpots.isEmpty ? 100 : luxSpots.map((e) => e.y).reduce(max);
    double avgLux = luxSpots.isEmpty ? 0 : luxSpots.map((e) => e.y).reduce((a, b) => a + b) / luxSpots.length;
    double currentLux = luxSpots.isEmpty ? 0 : luxSpots.last.y;

    double minNoise = noiseSpots.isEmpty ? 0 : noiseSpots.map((e) => e.y).reduce(min);
    double maxNoise = noiseSpots.isEmpty ? 60 : noiseSpots.map((e) => e.y).reduce(max);
    double avgNoise = noiseSpots.isEmpty ? 0 : noiseSpots.map((e) => e.y).reduce((a, b) => a + b) / noiseSpots.length;
    double currentNoise = noiseSpots.isEmpty ? 0 : noiseSpots.last.y;

    // Ensure minimum range for better visualization
    if (maxLux - minLux < 30) {
      minLux = max(0, minLux - 15);
      maxLux = minLux + 30;
    }
    if (maxNoise - minNoise < 20) {
      minNoise = max(0, minNoise - 10);
      maxNoise = minNoise + 20;
    }

    // Safe interval calculation (prevent division by zero)
    double luxInterval = max(1.0, (maxLux - minLux) / 4);
    double noiseInterval = max(1.0, (maxNoise - minNoise) / 4);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Graphs"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Light Graph Card
                _buildGraphCard(
                  context: context,
                  title: 'Light Level',
                  icon: Icons.wb_sunny_rounded,
                  iconColor: const Color(0xFFFF9500),
                  gradientColors: [const Color(0xFFFFB74D), const Color(0xFFFF9500)],
                  spots: luxSpots,
                  minY: minLux,
                  maxY: maxLux,
                  interval: luxInterval,
                  unit: 'lux',
                  currentValue: currentLux,
                  avgValue: avgLux,
                  minValue: minLux,
                  maxValue: maxLux,
                ),

                const SizedBox(height: 20),

                // Noise Graph Card
                _buildGraphCard(
                  context: context,
                  title: 'Noise Level',
                  icon: Icons.volume_up_rounded,
                  iconColor: const Color(0xFF2196F3),
                  gradientColors: [const Color(0xFF64B5F6), const Color(0xFF2196F3)],
                  spots: noiseSpots,
                  minY: minNoise,
                  maxY: maxNoise,
                  interval: noiseInterval,
                  unit: 'dB',
                  currentValue: currentNoise,
                  avgValue: avgNoise,
                  minValue: minNoise,
                  maxValue: maxNoise,
                ),

                const SizedBox(height: 20),

                // Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, 
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Displaying data from the last 10 minutes. Data updates every 5 seconds.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraphCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required List<FlSpot> spots,
    required double minY,
    required double maxY,
    required double interval,
    required String unit,
    required double currentValue,
    required double avgValue,
    required double minValue,
    required double maxValue,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Last 10 minutes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Current Value Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentValue.toStringAsFixed(1)} $unit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Avg', avgValue, unit, iconColor),
                _buildStatItem('Min', minValue, unit, Colors.green),
                _buildStatItem('Max', maxValue, unit, Colors.red),
              ],
            ),

            const SizedBox(height: 20),

            // Graph
            SizedBox(
              height: 200,
              child: spots.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart,
                              size: 48, color: theme.colorScheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'No data available',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        clipData: const FlClipData.all(),
                        minX: 0,
                        maxX: 600,
                        minY: minY,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: interval,
                          verticalInterval: 120,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                            strokeWidth: 1,
                          ),
                          getDrawingVerticalLine: (value) => FlLine(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(
                                color: theme.colorScheme.outlineVariant),
                            bottom: BorderSide(
                                color: theme.colorScheme.outlineVariant),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.3,
                            gradient: LinearGradient(colors: gradientColors),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: gradientColors
                                    .map((c) => c.withOpacity(0.2))
                                    .toList(),
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              interval: interval,
                              getTitlesWidget: (value, meta) {
                                // Skip if too close to edges
                                if (value <= minY || value >= maxY) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 120,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final minutes = (value / 60).round();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${minutes}m',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  '${spot.y.toStringAsFixed(1)} $unit',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
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

  Widget _buildStatItem(String label, double value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

/// =====================================================================
///                       DAILY STATS PAGE
/// =====================================================================
class DailyStatsPage extends StatelessWidget {
  final List<EnvSample> log;

  const DailyStatsPage({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (log.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Today's Statistics")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'No records yet.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Start the environment monitor to collect data.',
                style: theme.textTheme.bodySmall,
              ),
            ],
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
      appBar: AppBar(title: const Text("Today's Environment Statistics")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.analytics_rounded,
                            size: 32,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Measurements',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '${log.length}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Light Stats Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.wb_sunny_rounded,
                                color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text('Light Statistics',
                                style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                            'Average', '${avgLux.toStringAsFixed(1)} lux'),
                        const SizedBox(height: 8),
                        _buildStatRow(
                            'Maximum', '${maxLux.toStringAsFixed(1)} lux'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Noise Stats Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.volume_up_rounded,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text('Noise Statistics',
                                style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                            'Average', '${avgNoise.toStringAsFixed(1)} dB'),
                        const SizedBox(height: 8),
                        _buildStatRow(
                            'Maximum', '${maxNoise.toStringAsFixed(1)} dB'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Environment Quality Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Environment Quality',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        _buildQualityRow('Good', good, Colors.green),
                        const SizedBox(height: 8),
                        _buildQualityRow('Caution', warn, Colors.orange),
                        const SizedBox(height: 8),
                        _buildQualityRow('Poor', bad, Colors.red),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQualityRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('$count times',
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

