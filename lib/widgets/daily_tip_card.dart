import 'package:flutter/material.dart';
import 'dart:async';
import '../models/sleep_tip_model.dart';

class DailyTipCard extends StatefulWidget {
  const DailyTipCard({super.key});

  @override
  State<DailyTipCard> createState() => _DailyTipCardState();
}

class _DailyTipCardState extends State<DailyTipCard> {
  late PageController _pageController;
  late List<SleepTip> _tips;
  int _currentPage = 0;
  Timer? _timer;
  int _lastTimePeriod = -1;

  int _getTimePeriod() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 0; // 아침
    if (hour >= 12 && hour < 16) return 1; // 점심
    if (hour >= 16 && hour < 21) return 2; // 저녁
    return 3; // 밤
  }

  void _loadTips() {
    setState(() {
      _tips = SleepTips.getTimeBasedTipsShuffled();
      _currentPage = 0;
      _lastTimePeriod = _getTimePeriod();
      // PageController 재생성
      _pageController.dispose();
      _pageController = PageController();
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tips = SleepTips.getTimeBasedTipsShuffled();
    _lastTimePeriod = _getTimePeriod();

    // 시간대가 바뀔 때마다 새로운 팁 리스트 로드 (1분마다 체크)
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final currentPeriod = _getTimePeriod();
      if (currentPeriod != _lastTimePeriod) {
        _loadTips();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildTipCard(SleepTip tip) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: tip.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    tip.icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tip.timeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tip.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tip.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _tips.length,
            itemBuilder: (context, index) {
              return _buildTipCard(_tips[index]);
            },
          ),
        ),
        if (_tips.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _tips.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
