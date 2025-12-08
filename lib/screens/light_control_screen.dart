import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LightControlScreen extends StatefulWidget {
  const LightControlScreen({super.key});

  @override
  State<LightControlScreen> createState() => _LightControlScreenState();
}

class _LightControlScreenState extends State<LightControlScreen>
    with SingleTickerProviderStateMixin {
  String deviceIP = "http://192.168.0.50";
  double brightness = 255;
  bool isPowerOn = false;
  String colorMode = "daylight";

  @override
  void initState() {
    super.initState();
    _loadIP();
  }

  Future<void> _loadIP() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      deviceIP = prefs.getString("arduino_ip") ?? "http://192.168.0.50";
    });
  }

  Future<void> _saveIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("arduino_ip", ip);
    setState(() => deviceIP = ip);
  }

  Future<void> send(String path) async {
    try {
      await http.get(Uri.parse("$deviceIP$path"));
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("아두이노에 연결할 수 없습니다.")),
        );
      }
    }
  }

  void _openSettings() {
    TextEditingController controller = TextEditingController(text: deviceIP);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Arduino IP 설정"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "예: http://192.168.0.52",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              _saveIP(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  void _togglePower() {
    setState(() => isPowerOn = !isPowerOn);
    if (isPowerOn) {
      send("/on");
    } else {
      send("/off");
    }
  }

  void _setColorMode(String mode) {
    setState(() => colorMode = mode);
    send("/color?mode=$mode");
  }

  @override
  Widget build(BuildContext context) {
    int brightnessPercent = ((brightness / 255) * 100).round();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("조명 제어"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 전원 버튼 with Glow 애니메이션
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: isPowerOn ? 1 : 0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, glow, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surfaceContainerHighest,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(glow * 0.6),
                            blurRadius: 50 * glow,
                            spreadRadius: 20 * glow,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(60),
                      onTap: _togglePower,
                      child: Center(
                        child: Icon(
                          isPowerOn
                              ? Icons.power_settings_new
                              : Icons.power_settings_new_outlined,
                          size: 48,
                          color: isPowerOn
                              ? Colors.amber.shade700
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // 밝기 조절 카드
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "밝기 조절",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$brightnessPercent%",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Slider(
                          value: brightness,
                          min: 0,
                          max: 255,
                          onChanged: (v) {
                            setState(() => brightness = v);
                            send("/brightness?v=${v.toInt()}");
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 색온도 선택 카드
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "색온도 선택",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: "daylight",
                                label: Text("주광색"),
                                icon: Icon(Icons.wb_sunny),
                              ),
                              ButtonSegment(
                                value: "warm",
                                label: Text("전구색"),
                                icon: Icon(Icons.lightbulb),
                              ),
                            ],
                            selected: {colorMode},
                            onSelectionChanged: (selection) {
                              _setColorMode(selection.first);
                            },
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
}

