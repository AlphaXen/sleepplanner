import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/calendar_provider.dart';
import '../providers/sleep_provider.dart';
import '../providers/settings_provider.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수면 달력'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer3<CalendarProvider, SleepProvider, SettingsProvider>(
        builder: (context, calendarProvider, sleepProvider, settingsProvider, child) {
          final actualEntries = sleepProvider.entries;
          final stats = calendarProvider.getMonthlyStats(
            calendarProvider.focusedDay,
            actualEntries,
          );
          
          // 최근 7일 수면 시간 데이터 (그래프용)
          final weeklyData = sleepProvider.last7DaysSleepHours;
          final graphSpots = <FlSpot>[];
          final graphLabels = <String>[];
          int graphIndex = 0;
          for (final entry in weeklyData.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))) {
            graphIndex++;
            graphSpots.add(FlSpot(graphIndex.toDouble(), entry.value.toDouble()));
            graphLabels.add('${entry.key.month}/${entry.key.day}');
          }
          
          // 오늘의 목표 달성률
          final todayProgress = sleepProvider.getTodayProgress(
            settingsProvider.dayStartHour, 
            settingsProvider.dailyTargetHours,
          );
          final complete = (todayProgress * 100).clamp(0, 100).toDouble();
          final remaining = 100.0 - complete;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Monthly Statistics Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(
                          calendarProvider.focusedDay,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatCard(
                            label: '평균',
                            value: '${stats['average']!.toStringAsFixed(1)}h',
                            icon: Icons.show_chart,
                          ),
                          _StatCard(
                            label: '최대',
                            value: '${stats['max']!.toStringAsFixed(1)}h',
                            icon: Icons.arrow_upward,
                          ),
                          _StatCard(
                            label: '최소',
                            value: '${stats['min']!.toStringAsFixed(1)}h',
                            icon: Icons.arrow_downward,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Calendar
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: calendarProvider.focusedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(calendarProvider.selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        calendarProvider.setSelectedDay(selectedDay);
                        calendarProvider.setFocusedDay(focusedDay);
                      },
                      onPageChanged: (focusedDay) {
                        calendarProvider.setFocusedDay(focusedDay);
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        weekendTextStyle: TextStyle(
                          color: Colors.red.shade400,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final hours = calendarProvider.getSleepHours(day, actualEntries);
                          return _DayCell(
                            day: day,
                            sleepHours: hours,
                            color: calendarProvider.getSleepQualityColor(hours),
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final hours = calendarProvider.getSleepHours(day, actualEntries);
                          return _DayCell(
                            day: day,
                            sleepHours: hours,
                            color: calendarProvider.getSleepQualityColor(hours),
                            isToday: true,
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          final hours = calendarProvider.getSleepHours(day, actualEntries);
                          return _DayCell(
                            day: day,
                            sleepHours: hours,
                            color: calendarProvider.getSleepQualityColor(hours),
                            isSelected: true,
                          );
                        },
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // Selected Day Detail
                if (calendarProvider.selectedDay != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(
                                calendarProvider.selectedDay!,
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.bedtime,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  calendarProvider
                                          .getSleepHours(
                                            calendarProvider.selectedDay!,
                                            actualEntries,
                                          )
                                          ?.toStringAsFixed(1) ??
                                      '데이터 없음',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (calendarProvider.getSleepHours(
                                      calendarProvider.selectedDay!,
                                      actualEntries,
                                    ) !=
                                    null)
                                  const Text(
                                    ' 시간',
                                    style: TextStyle(fontSize: 18),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Legend
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '수면 품질 범례',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LegendItem(
                            color: Colors.green.shade400,
                            label: '우수 (8시간 이상)',
                          ),
                          _LegendItem(
                            color: Colors.lightGreen.shade400,
                            label: '양호 (7-8시간)',
                          ),
                          _LegendItem(
                            color: Colors.orange.shade400,
                            label: '보통 (6-7시간)',
                          ),
                          _LegendItem(
                            color: Colors.red.shade400,
                            label: '부족 (6시간 미만)',
                          ),
                          _LegendItem(
                            color: Colors.grey.shade200,
                            label: '데이터 없음',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 오늘의 목표 달성률 Pie Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '오늘의 목표 달성률',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 160,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 35,
                                      sections: [
                                        PieChartSectionData(
                                          value: complete,
                                          title: '${complete.toStringAsFixed(0)}%',
                                          radius: 50,
                                          color: Colors.blue,
                                        ),
                                        PieChartSectionData(
                                          value: remaining,
                                          title: '',
                                          radius: 50,
                                          color: Colors.grey.shade300,
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
                                          '목표: ${settingsProvider.dailyTargetHours}시간',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text('달성: ${complete.toStringAsFixed(1)}%'),
                                        Text('남은: ${remaining.toStringAsFixed(1)}%'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 최근 7일 수면 시간 추이 그래프
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '최근 7일 수면 시간 추이',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: graphSpots.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.show_chart,
                                          size: 48,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '데이터가 부족합니다',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : LineChart(
                                    LineChartData(
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 8.0),
                                                child: Text(
                                                  '${value.toInt()}h',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
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
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              final i = value.toInt();
                                              if (i <= 0 || i > graphLabels.length) {
                                                return const SizedBox.shrink();
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Text(
                                                  graphLabels[i - 1],
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      minY: 0,
                                      maxY: graphSpots.isEmpty
                                          ? 12
                                          : (graphSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2).clamp(6, 12),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: graphSpots,
                                          isCurved: true,
                                          dotData: const FlDotData(show: true),
                                          color: Theme.of(context).colorScheme.primary,
                                          barWidth: 3,
                                        ),
                                      ],
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                                            strokeWidth: 1,
                                          );
                                        },
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border(
                                          left: BorderSide(
                                            color: Theme.of(context).colorScheme.outlineVariant,
                                          ),
                                          bottom: BorderSide(
                                            color: Theme.of(context).colorScheme.outlineVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final double? sleepHours;
  final Color color;
  final bool isToday;
  final bool isSelected;

  const _DayCell({
    required this.day,
    required this.sleepHours,
    required this.color,
    this.isToday = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  )
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: sleepHours != null ? Colors.white : Colors.black54,
            ),
          ),
          if (sleepHours != null)
            Text(
              '${sleepHours!.toStringAsFixed(1)}h',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
