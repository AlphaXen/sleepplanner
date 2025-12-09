import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feedback_provider.dart';
import '../models/sleep_feedback.dart';

class SleepFeedbackScreen extends StatefulWidget {
  const SleepFeedbackScreen({super.key});

  @override
  State<SleepFeedbackScreen> createState() => _SleepFeedbackScreenState();
}

class _SleepFeedbackScreenState extends State<SleepFeedbackScreen> {
  DateTime selectedDate = DateTime.now();
  double sleepScore = 3.0;
  double daytimeSleepiness = 3.0;
  bool hadLateCaffeine = false;
  bool hadHighLightExposure = false;
  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingFeedback();
  }

  void _loadExistingFeedback() {
    final provider = Provider.of<FeedbackProvider>(context, listen: false);
    final existing = provider.getFeedbackForDate(selectedDate);
    if (existing != null) {
      setState(() {
        sleepScore = existing.sleepScore;
        daytimeSleepiness = existing.daytimeSleepiness;
        hadLateCaffeine = existing.hadLateCaffeine;
        hadHighLightExposure = existing.hadHighLightExposure;
        notesController.text = existing.notes ?? '';
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      _loadExistingFeedback();
    }
  }

  void _saveFeedback() {
    final feedback = SleepFeedback(
      date: selectedDate,
      sleepScore: sleepScore,
      daytimeSleepiness: daytimeSleepiness,
      hadLateCaffeine: hadLateCaffeine,
      hadHighLightExposure: hadHighLightExposure,
      notes: notesController.text.trim().isEmpty 
          ? null 
          : notesController.text.trim(),
    );

    Provider.of<FeedbackProvider>(context, listen: false).addFeedback(feedback);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드백이 저장되었습니다!'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('수면 피드백'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 선택
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('피드백 날짜'),
                subtitle: Text(
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 24),

            // 수면 품질 점수
            _buildSectionTitle('😴 수면 품질 점수'),
            const SizedBox(height: 8),
            Text(
              _getSleepScoreLabel(sleepScore),
              style: theme.textTheme.titleMedium?.copyWith(
                color: _getSleepScoreColor(sleepScore),
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: sleepScore,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              label: sleepScore.toStringAsFixed(1),
              onChanged: (v) => setState(() => sleepScore = v),
            ),
            _buildScoreGuide(),
            const SizedBox(height: 24),

            // 낮 졸음 정도
            _buildSectionTitle('💤 낮 졸음 정도'),
            const SizedBox(height: 8),
            Text(
              _getSleepinessLabel(daytimeSleepiness),
              style: theme.textTheme.titleMedium?.copyWith(
                color: _getSleepinessColor(daytimeSleepiness),
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: daytimeSleepiness,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              label: daytimeSleepiness.toStringAsFixed(1),
              onChanged: (v) => setState(() => daytimeSleepiness = v),
            ),
            _buildSleepinessGuide(),
            const SizedBox(height: 24),

            // 환경 요인
            _buildSectionTitle('🔬 환경 요인'),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('늦은 시간 카페인 섭취'),
                    subtitle: const Text('취침 6시간 이내 카페인 섭취'),
                    secondary: const Icon(Icons.coffee),
                    value: hadLateCaffeine,
                    onChanged: (v) => setState(() => hadLateCaffeine = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('높은 빛 노출'),
                    subtitle: const Text('취침 전 강한 빛 노출 (휴대폰, TV 등)'),
                    secondary: const Icon(Icons.lightbulb),
                    value: hadHighLightExposure,
                    onChanged: (v) => setState(() => hadHighLightExposure = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 메모
            _buildSectionTitle('📝 메모 (선택사항)'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: '특이사항, 느낀점 등을 자유롭게 작성하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _saveFeedback,
                icon: const Icon(Icons.save),
                label: const Text('저장', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildScoreGuide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('1: 매우 나쁨', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text('3: 보통', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text('5: 매우 좋음', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSleepinessGuide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('1: 전혀 없음', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text('3: 보통', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text('5: 매우 심함', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  String _getSleepScoreLabel(double score) {
    if (score >= 4.5) return '매우 좋음 ⭐⭐⭐⭐⭐';
    if (score >= 3.5) return '좋음 ⭐⭐⭐⭐';
    if (score >= 2.5) return '보통 ⭐⭐⭐';
    if (score >= 1.5) return '나쁨 ⭐⭐';
    return '매우 나쁨 ⭐';
  }

  Color _getSleepScoreColor(double score) {
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.blue;
    if (score >= 2.0) return Colors.orange;
    return Colors.red;
  }

  String _getSleepinessLabel(double sleepiness) {
    if (sleepiness >= 4.5) return '매우 심한 졸음 😴😴😴';
    if (sleepiness >= 3.5) return '심한 졸음 😴😴';
    if (sleepiness >= 2.5) return '보통 졸음 😴';
    if (sleepiness >= 1.5) return '약간 졸음 🙂';
    return '전혀 안 졸림 😃';
  }

  Color _getSleepinessColor(double sleepiness) {
    if (sleepiness >= 4.0) return Colors.red;
    if (sleepiness >= 3.0) return Colors.orange;
    if (sleepiness >= 2.0) return Colors.blue;
    return Colors.green;
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('피드백 가이드'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📊 수면 품질 점수',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('전날 밤 수면의 질을 평가해주세요.\n1점: 자주 깨고 개운하지 않음\n5점: 깊이 자고 매우 개운함'),
              SizedBox(height: 16),
              Text(
                '💤 낮 졸음 정도',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('하루 동안 느낀 졸음의 정도를 평가해주세요.\n1점: 전혀 졸리지 않음\n5점: 업무/일상에 지장을 줄 정도로 졸림'),
              SizedBox(height: 16),
              Text(
                '🔬 환경 요인',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('수면에 영향을 줄 수 있는 요인들을 체크해주세요. 이 정보는 AI가 당신의 민감도를 학습하는데 사용됩니다.'),
            ],
          ),
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

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}

