import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../models/adaptive_params.dart';

class AdaptiveParamsSettingsScreen extends StatefulWidget {
  const AdaptiveParamsSettingsScreen({super.key});

  @override
  State<AdaptiveParamsSettingsScreen> createState() =>
      _AdaptiveParamsSettingsScreenState();
}

class _AdaptiveParamsSettingsScreenState
    extends State<AdaptiveParamsSettingsScreen> {
  late double tSleep;
  late double cafWindow;
  late int winddownMinutes;
  late double chronoOffset;
  late double lightSens;
  late double cafSens;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SleepProvider>(context, listen: false);
    final params = provider.adaptiveParams;

    tSleep = params.tSleep;
    cafWindow = params.cafWindow;
    winddownMinutes = params.winddownMinutes;
    chronoOffset = params.chronoOffset;
    lightSens = params.lightSens;
    cafSens = params.cafSens;
  }

  void _saveSettings() {
    final provider = Provider.of<SleepProvider>(context, listen: false);
    provider.adaptiveParams = AdaptiveParams(
      tSleep: tSleep,
      cafWindow: cafWindow,
      winddownMinutes: winddownMinutes,
      chronoOffset: chronoOffset,
      lightSens: lightSens,
      cafSens: cafSens,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('적응형 파라미터가 저장되었습니다!'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기본값으로 초기화'),
        content: const Text('모든 설정을 기본값으로 되돌리시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tSleep = 7.0;
                cafWindow = 6.0;
                winddownMinutes = 60;
                chronoOffset = 0.0;
                lightSens = 0.5;
                cafSens = 0.5;
              });
              Navigator.pop(context);
            },
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('적응형 파라미터 설정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefault,
            tooltip: '기본값으로 초기화',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: '도움말',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 메시지
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI가 자동으로 조정한 값을 수동으로 미세 조정할 수 있습니다.',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 목표 수면시간
            _buildSectionTitle('🛌 목표 수면시간'),
            const SizedBox(height: 8),
            Text(
              '${tSleep.toStringAsFixed(1)} 시간',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: tSleep,
              min: 5.0,
              max: 10.0,
              divisions: 50,
              label: '${tSleep.toStringAsFixed(1)}h',
              onChanged: (v) => setState(() => tSleep = v),
            ),
            Text(
              '권장: 7-9시간',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // 카페인 제한 시간
            _buildSectionTitle('☕ 카페인 제한 시간'),
            const SizedBox(height: 8),
            Text(
              '취침 ${cafWindow.toStringAsFixed(1)} 시간 전',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: cafWindow,
              min: 3.0,
              max: 10.0,
              divisions: 70,
              label: '${cafWindow.toStringAsFixed(1)}h 전',
              onChanged: (v) => setState(() => cafWindow = v),
            ),
            Text(
              '카페인 민감도에 따라 조정됩니다',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // 취침 준비 시간
            _buildSectionTitle('🌙 취침 준비 시간'),
            const SizedBox(height: 8),
            Text(
              '$winddownMinutes 분',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: winddownMinutes.toDouble(),
              min: 15,
              max: 120,
              divisions: 21,
              label: '$winddownMinutes분',
              onChanged: (v) => setState(() => winddownMinutes = v.toInt()),
            ),
            Text(
              '밝은 빛과 화면을 줄이기 시작하는 시간',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // 크로노타입 오프셋
            _buildSectionTitle('⏰ 크로노타입 오프셋'),
            const SizedBox(height: 8),
            Text(
              '${chronoOffset >= 0 ? '+' : ''}${chronoOffset.toStringAsFixed(1)} 시간',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: chronoOffset,
              min: -3.0,
              max: 3.0,
              divisions: 60,
              label:
                  '${chronoOffset >= 0 ? '+' : ''}${chronoOffset.toStringAsFixed(1)}h',
              onChanged: (v) => setState(() => chronoOffset = v),
            ),
            Text(
              '음수: 아침형, 0: 보통, 양수: 저녁형',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // 빛 민감도
            _buildSectionTitle('💡 빛 민감도'),
            const SizedBox(height: 8),
            Text(
              '${(lightSens * 100).round()}%',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: lightSens,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '${(lightSens * 100).round()}%',
              onChanged: (v) => setState(() => lightSens = v),
            ),
            Text(
              '높을수록 빛에 민감 → 더 어두운 환경 권장',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // 카페인 민감도
            _buildSectionTitle('☕ 카페인 민감도'),
            const SizedBox(height: 8),
            Text(
              '${(cafSens * 100).round()}%',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.brown,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: cafSens,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '${(cafSens * 100).round()}%',
              onChanged: (v) => setState(() => cafSens = v),
            ),
            Text(
              '높을수록 카페인에 민감 → 더 일찍 섭취 제한',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text(
                  '저장',
                  style: TextStyle(fontSize: 16),
                ),
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

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('적응형 파라미터 가이드'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🛌 목표 수면시간',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('매일 목표로 하는 수면 시간입니다. AI가 이를 기반으로 취침/기상 시간을 추천합니다.'),
              SizedBox(height: 12),
              Text(
                '☕ 카페인 제한 시간',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('취침 몇 시간 전부터 카페인을 피해야 하는지 설정합니다. 카페인 민감도가 높으면 자동으로 늘어납니다.'),
              SizedBox(height: 12),
              Text(
                '🌙 취침 준비 시간',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('실제 취침 전 휴대폰/밝은 빛을 줄이고 준비를 시작해야 하는 시간입니다.'),
              SizedBox(height: 12),
              Text(
                '⏰ 크로노타입 오프셋',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('당신이 아침형인지 저녁형인지를 나타냅니다. AI가 휴무일 선호 시간을 분석하여 자동 조정합니다.'),
              SizedBox(height: 12),
              Text(
                '💡 빛 민감도',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('빛 노출이 수면에 얼마나 영향을 미치는지입니다. 피드백 데이터를 통해 AI가 학습합니다.'),
              SizedBox(height: 12),
              Text(
                '☕ 카페인 민감도',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('카페인이 수면에 얼마나 영향을 미치는지입니다. 피드백 데이터를 통해 AI가 학습합니다.'),
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
}

