import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Calendar'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, calendarProvider, child) {
          final stats = calendarProvider.getMonthlyStats(
            calendarProvider.focusedDay,
          );

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
                            label: 'Average',
                            value: '${stats['average']!.toStringAsFixed(1)}h',
                            icon: Icons.show_chart,
                          ),
                          _StatCard(
                            label: 'Max',
                            value: '${stats['max']!.toStringAsFixed(1)}h',
                            icon: Icons.arrow_upward,
                          ),
                          _StatCard(
                            label: 'Min',
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
                          return _DayCell(
                            day: day,
                            sleepHours: calendarProvider.getSleepHours(day),
                            color: calendarProvider.getSleepQualityColor(
                              calendarProvider.getSleepHours(day),
                            ),
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return _DayCell(
                            day: day,
                            sleepHours: calendarProvider.getSleepHours(day),
                            color: calendarProvider.getSleepQualityColor(
                              calendarProvider.getSleepHours(day),
                            ),
                            isToday: true,
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return _DayCell(
                            day: day,
                            sleepHours: calendarProvider.getSleepHours(day),
                            color: calendarProvider.getSleepQualityColor(
                              calendarProvider.getSleepHours(day),
                            ),
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

                // Legend
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sleep Quality Legend',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LegendItem(
                            color: Colors.green.shade400,
                            label: 'Excellent (8+ hours)',
                          ),
                          _LegendItem(
                            color: Colors.lightGreen.shade400,
                            label: 'Good (7-8 hours)',
                          ),
                          _LegendItem(
                            color: Colors.orange.shade400,
                            label: 'Fair (6-7 hours)',
                          ),
                          _LegendItem(
                            color: Colors.red.shade400,
                            label: 'Poor (<6 hours)',
                          ),
                          _LegendItem(
                            color: Colors.grey.shade200,
                            label: 'No data',
                          ),
                        ],
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
                                          )
                                          ?.toStringAsFixed(1) ??
                                      'No data',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (calendarProvider.getSleepHours(
                                      calendarProvider.selectedDay!,
                                    ) !=
                                    null)
                                  const Text(
                                    ' hours',
                                    style: TextStyle(fontSize: 18),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
