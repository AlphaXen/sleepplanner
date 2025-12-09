import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sleep_provider.dart';
import '../providers/feedback_provider.dart';
import '../providers/env_provider.dart';
import '../services/sleep_analysis_service.dart';
import 'sleep_feedback_screen.dart';
import 'adaptive_params_settings_screen.dart';

class AISleepAnalysisScreen extends StatefulWidget {
  final bool hideAppBar;
  
  const AISleepAnalysisScreen({super.key, this.hideAppBar = false});

  @override
  State<AISleepAnalysisScreen> createState() => _AISleepAnalysisScreenState();
}

class _AISleepAnalysisScreenState extends State<AISleepAnalysisScreen> {
  final _analysisService = SleepAnalysisService();
  SleepAnalysisResult? _analysisResult;
  bool _isLoading = true;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  void _performAnalysis() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
      final feedbackProvider =
          Provider.of<FeedbackProvider>(context, listen: false);
      final envProvider = Provider.of<EnvProvider>(context, listen: false);

      final result = _analysisService.analyzeSleep(
        sleepEntries: sleepProvider.entries,
        feedbacks: feedbackProvider.feedbacks,
        envSamples: envProvider.localDb,
        adaptiveParams: sleepProvider.adaptiveParams,
        analysisWindowDays: _selectedDays,
      );

      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('AI 수면 분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _performAnalysis,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SleepFeedbackScreen(),
                ),
              ).then((_) => _performAnalysis());
            },
            tooltip: '피드백 추가',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysisResult == null
              ? _buildNoDataView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 기간 선택
                      _buildPeriodSelector(),
                      const SizedBox(height: 16),

                      // 종합 점수 카드
                      _buildOverallScoreCard(),
                      const SizedBox(height: 16),

                      // 주요 지표
                      _buildKeyMetricsGrid(),
                      const SizedBox(height: 16),

                      // 인사이트
                      _buildInsightsCard(),
                      const SizedBox(height: 16),

                      // 추천사항
                      _buildRecommendationsCard(),
                      const SizedBox(height: 16),

                      // 수면 시간 트렌드 그래프
                      _buildSleepTrendChart(),
                      const SizedBox(height: 16),

                      // 수면 품질 트렌드 그래프
                      _buildSleepScoreChart(),
                      const SizedBox(height: 16),

                      // 환경 데이터
                      _buildEnvironmentCard(),
                      const SizedBox(height: 16),

                      // 적응형 수면 시스템 섹션
                      _buildAdaptiveSleepSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUpdateParamsButton() {
    final result = _analysisResult;
    if (result == null) return const SizedBox.shrink();

    final feedbackProvider = Provider.of<FeedbackProvider>(context, listen: false);
    final recentFeedbacks = feedbackProvider.getRecentFeedbacks(_selectedDays);
    final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
    
    // 데이터가 충분한지 확인 (최소 3일 이상의 피드백)
    final hasEnoughData = recentFeedbacks.length >= 3;
    final hasSleepEntries = sleepProvider.entries.length >= 3;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: (hasEnoughData && hasSleepEntries) ? _updateAdaptiveParams : null,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text(
              '✨ AI 파라미터 자동 조정',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ),
        if (!hasEnoughData || !hasSleepEntries) ...[
          const SizedBox(height: 8),
          Text(
            hasEnoughData 
                ? '최소 3일 이상의 수면 기록이 필요합니다'
                : hasSleepEntries
                    ? '최소 3일 이상의 피드백이 필요합니다'
                    : '수면 기록과 피드백을 더 추가해주세요',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SleepFeedbackScreen(),
              ),
            ).then((_) => _performAnalysis());
          },
          icon: const Icon(Icons.add_chart),
          label: const Text('피드백 추가하기'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 45),
          ),
        ),
      ],
    );
  }

  void _updateAdaptiveParams() async {
    final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
    final feedbackProvider = Provider.of<FeedbackProvider>(context, listen: false);

    // 최근 7일 데이터로 주간 평균 계산
    final weeklyAvg = feedbackProvider.getWeeklyAverages();
    final recentEntries = sleepProvider.entries
        .where((e) => e.sleepTime.isAfter(
            DateTime.now().subtract(Duration(days: _selectedDays))))
        .toList();

    // 평균 실제 수면 시간 계산
    double avgActualSleep = 0;
    if (recentEntries.isNotEmpty) {
      final totalMinutes = recentEntries
          .map((e) => e.duration.inMinutes)
          .reduce((a, b) => a + b);
      avgActualSleep = totalMinutes / recentEntries.length / 60.0;
    }

    // 선호하는 mid-sleep 계산 (휴무일 기준)
    DateTime? preferredMid;
    final offDayEntries = recentEntries.where((e) => !e.isNightShift).toList();
    if (offDayEntries.isNotEmpty) {
      // 평균 수면 중간 시간 계산
      int totalMidMinutes = 0;
      for (final entry in offDayEntries) {
        final mid = entry.sleepTime.add(entry.duration ~/ 2);
        totalMidMinutes += mid.hour * 60 + mid.minute;
      }
      final avgMidMinutes = totalMidMinutes ~/ offDayEntries.length;
      final now = DateTime.now();
      preferredMid = DateTime(
        now.year,
        now.month,
        now.day,
        avgMidMinutes ~/ 60,
        avgMidMinutes % 60,
      );
    }

    // 적응형 파라미터 업데이트
    sleepProvider.adaptWeeklyWithSummary(
      avgActualSleep: avgActualSleep,
      avgSleepScore: weeklyAvg['avgSleepScore']!,
      avgDaytimeSleepiness: weeklyAvg['avgDaytimeSleepiness']!,
      meanScoreNoLateCaf: weeklyAvg['meanScoreNoLateCaf']!,
      meanScoreLateCaf: weeklyAvg['meanScoreLateCaf']!,
      meanScoreLowLight: weeklyAvg['meanScoreLowLight']!,
      meanScoreHighLight: weeklyAvg['meanScoreHighLight']!,
      preferredMidOffDays: preferredMid,
    );

    // 업데이트 후 재분석
    _performAnalysis();

    // 사용자에게 알림
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✨ AI 조정 완료'),
          content: const Text(
            '수면 데이터를 분석하여 적응형 파라미터를 업데이트했습니다!\n\n'
            '새로운 파라미터를 기반으로 더 정확한 수면 추천을 받으실 수 있습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildNoDataView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '분석할 데이터가 부족합니다',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '수면 기록과 피드백을 추가하면\nAI가 당신의 수면 패턴을 분석합니다',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SleepFeedbackScreen(),
                  ),
                ).then((_) => _performAnalysis());
              },
              icon: const Icon(Icons.add),
              label: const Text('피드백 추가'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.date_range, size: 20),
            const SizedBox(width: 12),
            const Text('분석 기간:'),
            const SizedBox(width: 12),
            Expanded(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7일')),
                  ButtonSegment(value: 14, label: Text('14일')),
                  ButtonSegment(value: 30, label: Text('30일')),
                ],
                selected: {_selectedDays},
                onSelectionChanged: (selection) {
                  setState(() => _selectedDays = selection.first);
                  _performAnalysis();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallScoreCard() {
    final result = _analysisResult!;
    final overallScore = ((result.averageSleepScore / 5.0) * 100).round();
    final scoreColor = _getScoreColor(overallScore);

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scoreColor.withOpacity(0.7), scoreColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '종합 수면 점수',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$overallScore',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getScoreLabel(overallScore),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsGrid() {
    final result = _analysisResult!;

    return SizedBox(
      height: 240, // 높이를 조금 늘림
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4, // 비율 조정
        children: [
          _buildMetricCard(
            '평균 수면',
            '${result.averageSleepHours.toStringAsFixed(1)}h',
            Icons.bedtime,
            Colors.blue,
          ),
          _buildMetricCard(
            '수면 일관성',
            '${(result.sleepConsistency * 100).round()}%',
            Icons.timeline,
            Colors.green,
          ),
          _buildMetricCard(
            '수면 품질',
            '${result.averageSleepScore.toStringAsFixed(1)}/5',
            Icons.star,
            Colors.amber,
          ),
          _buildMetricCard(
            '낮 졸음',
            '${result.averageDaytimeSleepiness.toStringAsFixed(1)}/5',
            Icons.sunny,
            result.averageDaytimeSleepiness > 3.0 ? Colors.red : Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    final result = _analysisResult!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark 
          ? theme.colorScheme.surfaceContainerHighest 
          : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb, 
                  color: isDark 
                      ? theme.colorScheme.primary 
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI 인사이트',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark 
                        ? theme.colorScheme.primary 
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (result.insights.isEmpty)
              Text(
                '충분한 데이터가 쌓이면 인사이트를 제공합니다.',
                style: TextStyle(color: theme.colorScheme.onSurface),
              )
            else
              ...result.insights.map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ', 
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            insight,
                            style: TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final result = _analysisResult!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark 
          ? theme.colorScheme.surfaceContainerHighest 
          : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_objects, 
                  color: isDark 
                      ? Colors.greenAccent 
                      : Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI 추천사항',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark 
                        ? Colors.greenAccent 
                        : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...result.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✓ ', 
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepTrendChart() {
    final result = _analysisResult!;
    final trendData = result.trendData['sleepHoursByDate'] as Map<DateTime, double>;

    if (trendData.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDates = trendData.keys.toList()..sort();
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), trendData[sortedDates[i]]!));
    }

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 수면 시간 트렌드',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 ||
                              value.toInt() >= sortedDates.length) {
                            return const Text('');
                          }
                          final date = sortedDates[value.toInt()];
                          return Text(
                            '${date.month}/${date.day}',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  minY: 0,
                  maxY: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepScoreChart() {
    final result = _analysisResult!;
    final scoreData = result.trendData['sleepScoreByDate'] as Map<DateTime, double>;

    if (scoreData.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDates = scoreData.keys.toList()..sort();
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), scoreData[sortedDates[i]]!));
    }

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⭐ 수면 품질 트렌드',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 ||
                              value.toInt() >= sortedDates.length) {
                            return const Text('');
                          }
                          final date = sortedDates[value.toInt()];
                          return Text(
                            '${date.month}/${date.day}',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.amber,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  minY: 1,
                  maxY: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard() {
    final result = _analysisResult!;
    final env = result.environmentCorrelation;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌍 환경 분석',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildEnvRow('평균 조도', '${env['avgLux']?.toStringAsFixed(1) ?? 0} lx',
                Icons.light_mode),
            _buildEnvRow('평균 소음', '${env['avgNoise']?.toStringAsFixed(1) ?? 0} dB',
                Icons.volume_up),
            _buildEnvRow(
              '카페인 영향도',
              _getImpactLabel(env['caffeineImpact'] ?? 0),
              Icons.coffee,
            ),
            _buildEnvRow(
              '빛 노출 영향도',
              _getImpactLabel(env['lightImpact'] ?? 0),
              Icons.wb_sunny,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveSleepSection() {
    final result = _analysisResult;
    if (result == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.auto_fix_high, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: const Text(
                  '적응형 수면 시스템',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // 적응형 파라미터 카드
        _buildAdaptiveParamsCard(),
        const SizedBox(height: 16),
        
        // 피드백 및 자동 조정 안내 카드
        _buildAdaptiveSystemInfoCard(),
        const SizedBox(height: 16),
        
        // AI 자동 조정 버튼
        _buildUpdateParamsButton(),
      ],
    );
  }

  Widget _buildAdaptiveParamsCard() {
    final result = _analysisResult!;
    final params = result.currentParams;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDark 
          ? theme.colorScheme.surfaceContainerHighest 
          : Colors.purple.shade50,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdaptiveParamsSettingsScreen(),
            ),
          ).then((_) => _performAnalysis());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.settings_suggest, 
                    color: isDark 
                        ? Colors.purpleAccent 
                        : Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '현재 적응형 파라미터',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark 
                            ? Colors.purpleAccent 
                            : Colors.purple.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 20,
                    color: isDark 
                        ? Colors.purpleAccent 
                        : Colors.purple.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '탭하여 수동으로 조정할 수 있습니다',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildParamRow('🛌 목표 수면시간', '${params.tSleep.toStringAsFixed(1)}h'),
              const Divider(height: 16),
              _buildParamRow(
                  '☕ 카페인 제한', '취침 ${params.cafWindow.toStringAsFixed(1)}h 전'),
              const Divider(height: 16),
              _buildParamRow(
                  '🌙 취침 준비', '${params.winddownMinutes}분 전부터'),
              const Divider(height: 16),
              _buildParamRow('⏰ 크로노타입 오프셋',
                  '${params.chronoOffset >= 0 ? '+' : ''}${params.chronoOffset.toStringAsFixed(1)}h'),
              const Divider(height: 16),
              _buildParamRow(
                  '💡 빛 민감도', '${(params.lightSens * 100).round()}%'),
              const Divider(height: 16),
              _buildParamRow(
                  '☕ 카페인 민감도', '${(params.cafSens * 100).round()}%'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptiveSystemInfoCard() {
    final feedbackProvider = Provider.of<FeedbackProvider>(context, listen: false);
    final recentFeedbacks = feedbackProvider.getRecentFeedbacks(_selectedDays);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasEnoughData = recentFeedbacks.length >= 3;

    return Card(
      color: isDark 
          ? theme.colorScheme.surfaceContainer 
          : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark 
                      ? theme.colorScheme.primary 
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  '적응형 시스템 작동 방식',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark 
                        ? theme.colorScheme.primary 
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• AI가 수면 기록과 피드백을 분석하여\n  파라미터를 자동으로 조정합니다',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• 주간 피드백을 추가하면 더 정확한\n  추천을 받을 수 있습니다',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (!hasEnoughData)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '자동 조정을 위해서는 최소 3일 이상의 피드백이 필요합니다. (현재: ${recentFeedbacks.length}일)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamRow(String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return '우수';
    if (score >= 60) return '양호';
    if (score >= 40) return '보통';
    return '주의 필요';
  }

  String _getImpactLabel(double impact) {
    if (impact > 0.8) return '매우 높음';
    if (impact > 0.5) return '높음';
    if (impact > 0.2) return '보통';
    if (impact > 0) return '낮음';
    return '영향 없음';
  }
}

