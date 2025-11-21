import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  // ⚠️ Node.js 서버 IP 주소 (개발 중이면 컴퓨터 IP)
  static const String baseUrl = 'http://YOUR_SERVER_IP:3000';

  // Flutter → Node.js 로 Sleep Plan 보내기
  static Future<void> sendSleepPlan({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final url = Uri.parse('$baseUrl/api/sleep-plan');

    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'mainSleepStart': start.toIso8601String(),
        'mainSleepEnd': end.toIso8601String(),
      }),
    );
  }
}
