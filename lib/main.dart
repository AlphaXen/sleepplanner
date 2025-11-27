import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const AutoReplyApp());
}

/// 상수 번역 테이블. 언어 코드별로 앱에서 사용하는 텍스트를 정의합니다.
/// 필요 시 새로운 키를 추가하고 각 언어에 대해 값을 정의하세요.
const Map<String, Map<String, String>> kTranslations = {
  'ko': {
    'manage_rules': '자동 문자 규칙 관리',
    'add_rule': '규칙 추가',
    'edit_rule': '규칙 수정',
    'phone_number': '전화번호',
    'phone_hint': '예: 01058434472',
    'message_label': '보낼 메시지',
    'cancel': '취소',
    'save': '저장',
    'no_rules': '등록된 규칙이 없습니다.\n오른쪽 위 + 버튼을 눌러 규칙을 추가하세요.',
    'start_service': '서비스 시작',
    'stop_service': '서비스 중지',
    'service_running': '서비스 실행 중',
    'service_stopped': '서비스 중지됨',
    'note_restart_service': '※ 규칙 수정 후에는 서비스 시작/재시작을 해 주세요.',
    'service_started_msg': '서비스가 시작되었습니다.',
    'service_stopped_msg': '서비스가 중지되었습니다.',
    'service_start_failed': '서비스 시작 실패',
    'service_stop_failed': '서비스 중지 실패',
    'settings': '설정',
    'language': '언어',
    'language_korean': '한국어',
    'language_english': 'English',
    'reply_to_all': '모든 전화에 자동응답',
    'default_message': '기본 응답 메시지',
    'settings_title': '설정',
    'settings_saved': '설정이 저장되었습니다.',
  },
  'en': {
    'manage_rules': 'Manage Auto SMS Rules',
    'add_rule': 'Add Rule',
    'edit_rule': 'Edit Rule',
    'phone_number': 'Phone Number',
    'phone_hint': 'e.g., 01058434472',
    'message_label': 'Message to Send',
    'cancel': 'Cancel',
    'save': 'Save',
    'no_rules': 'No rules registered.\nPress the + button in the top right to add a rule.',
    'start_service': 'Start Service',
    'stop_service': 'Stop Service',
    'service_running': 'Service Running',
    'service_stopped': 'Service Stopped',
    'note_restart_service': '※ After editing rules, please (re)start the service.',
    'service_started_msg': 'Service started.',
    'service_stopped_msg': 'Service stopped.',
    'service_start_failed': 'Failed to start service',
    'service_stop_failed': 'Failed to stop service',
    'settings': 'Settings',
    'language': 'Language',
    'language_korean': 'Korean',
    'language_english': 'English',
    'reply_to_all': 'Auto-reply to all calls',
    'default_message': 'Default reply message',
    'settings_title': 'Settings',
    'settings_saved': 'Settings saved.',
  },
};

class AutoReplyApp extends StatelessWidget {
  const AutoReplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 앱 타이틀은 기본 언어(한국어)로 두고, UI에서 따로 번역합니다.
      title: 'Auto Reply',
      debugShowCheckedModeBanner: false,

      // 🔹 라이트 테마 (Material 3)
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),

      // 🔹 다크 테마 (Material 3)
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),

      // 🔹 시스템 다크모드 설정 따르기
      themeMode: ThemeMode.system,

      home: const RulesPage(),
    );
  }
}

/// 전화번호 + 메시지 규칙 모델
class PhoneRule {
  final int? id;
  final String phone;
  final String message;

  PhoneRule({this.id, required this.phone, required this.message});

  Map<String, dynamic> toMap() => {
        'id': id,
        'phone': phone,
        'message': message,
      };

  factory PhoneRule.fromMap(Map<String, dynamic> map) => PhoneRule(
        id: map['id'] as int?,
        phone: map['phone'] as String,
        message: map['message'] as String,
      );
}

/// SQLite 헬퍼
class RulesDb {
  static final RulesDb instance = RulesDb._internal();
  RulesDb._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'autoreply_rules.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE phone_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT NOT NULL,
            message TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<PhoneRule>> getRules() async {
    final database = await db;
    final maps = await database.query('phone_rules', orderBy: 'id DESC');
    return maps.map((m) => PhoneRule.fromMap(m)).toList();
  }

  Future<int> insertRule(PhoneRule rule) async {
    final database = await db;
    return database.insert('phone_rules', rule.toMap());
  }

  Future<int> updateRule(PhoneRule rule) async {
    final database = await db;
    return database.update(
      'phone_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<int> deleteRule(int id) async {
    final database = await db;
    return database.delete(
      'phone_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class RulesPage extends StatefulWidget {
  const RulesPage({super.key});

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  static const platform = MethodChannel('com.example.call/autoreply');

  List<PhoneRule> _rules = [];
  bool _isServiceRunning = false;

  // 현재 앱의 언어 코드. 기본은 한국어("ko").
  String _languageCode = 'ko';
  // 모든 전화에 대한 기본 자동응답 사용 여부.
  bool _autoReplyToAll = false;
  // 기본 자동응답 메시지.
  String _autoReplyMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRules();
    _loadSettings();
  }

  Future<void> _loadRules() async {
    final rules = await RulesDb.instance.getRules();
    setState(() {
      _rules = rules;
    });
  }

  /// DB 내용을 SharedPreferences에 JSON으로 반영
  Future<void> _syncRulesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _rules
        .map((r) => {
              'phone': r.phone.trim(),
              'message': r.message.trim(),
            })
        .toList();
    final jsonStr = jsonEncode(list);
    await prefs.setString('rulesJson', jsonStr);
  }

  /// SharedPreferences로부터 언어 및 자동응답 설정을 읽어옵니다.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _languageCode = prefs.getString('languageCode') ?? 'ko';
      _autoReplyToAll = prefs.getBool('autoReplyToAll') ?? false;
      _autoReplyMessage = prefs.getString('autoReplyMessage') ?? '';
    });
  }

  /// 현재 언어 코드로 번역된 문자열을 반환합니다. 정의되지 않은 키는 키 자체를 반환합니다.
  String tr(String key) {
    return kTranslations[_languageCode]?[key] ?? key;
  }

  Future<void> _addOrEditRule({PhoneRule? rule}) async {
    final phoneController = TextEditingController(text: rule?.phone ?? '');
    final msgController = TextEditingController(text: rule?.message ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(rule == null ? tr('add_rule') : tr('edit_rule')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: tr('phone_number'),
                    hintText: tr('phone_hint'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: tr('message_label'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('save')),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final phone = phoneController.text.trim();
    final msg = msgController.text.trim();

    if (phone.isEmpty || msg.isEmpty) return;

    if (rule == null) {
      await RulesDb.instance.insertRule(
        PhoneRule(phone: phone, message: msg),
      );
    } else {
      await RulesDb.instance.updateRule(
        PhoneRule(id: rule.id, phone: phone, message: msg),
      );
    }

    await _loadRules();
    await _syncRulesToPrefs();
  }

  Future<void> _deleteRule(PhoneRule rule) async {
    if (rule.id == null) return;
    await RulesDb.instance.deleteRule(rule.id!);
    await _loadRules();
    await _syncRulesToPrefs();
  }

  Future<void> _startService() async {
    try {
      await _syncRulesToPrefs();
      await platform.invokeMethod('startService');
      setState(() => _isServiceRunning = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('service_started_msg'))),
      );
    } catch (e) {
      debugPrint('서비스 시작 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr('service_start_failed')}: $e')),
      );
    }
  }

  Future<void> _stopService() async {
    try {
      await platform.invokeMethod('stopService');
      setState(() => _isServiceRunning = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('service_stopped_msg'))),
      );
    } catch (e) {
      debugPrint('서비스 중지 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('manage_rules')),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _addOrEditRule(),
            icon: const Icon(Icons.add),
            tooltip: tr('add_rule'),
          ),
          IconButton(
            onPressed: () async {
              // Navigate to settings and reload preferences on return
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    languageCode: _languageCode,
                    autoReplyToAll: _autoReplyToAll,
                    autoReplyMessage: _autoReplyMessage,
                  ),
                ),
              );
              await _loadSettings();
              setState(() {});
            },
            icon: const Icon(Icons.settings),
            tooltip: tr('settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _rules.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        tr('no_rules'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _rules.length,
                    itemBuilder: (context, index) {
                      final rule = _rules[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            rule.phone,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              rule.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onTap: () => _addOrEditRule(rule: rule),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: cs.error,
                            onPressed: () => _deleteRule(rule),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isServiceRunning ? null : _startService,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(tr('start_service')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isServiceRunning ? _stopService : null,
                        icon: const Icon(Icons.stop),
                        label: Text(tr('stop_service')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isServiceRunning
                          ? Icons.check_circle
                          : Icons.cancel_outlined,
                      color: _isServiceRunning ? cs.primary : cs.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isServiceRunning
                          ? tr('service_running')
                          : tr('service_stopped'),
                      style: TextStyle(
                        color: _isServiceRunning ? cs.primary : cs.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tr('note_restart_service'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 앱 설정 페이지. 언어 선택 및 자동응답 기본 메시지 설정을 제공합니다.
class SettingsPage extends StatefulWidget {
  final String languageCode;
  final bool autoReplyToAll;
  final String autoReplyMessage;

  const SettingsPage({
    super.key,
    required this.languageCode,
    required this.autoReplyToAll,
    required this.autoReplyMessage,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _selectedLang;
  late bool _replyToAll;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.languageCode;
    _replyToAll = widget.autoReplyToAll;
    _messageController =
        TextEditingController(text: widget.autoReplyMessage ?? '');
  }

  /// 로케일에 따른 텍스트 번역 함수. SettingsPage에서는 _selectedLang을 사용합니다.
  String tr(String key) {
    return kTranslations[_selectedLang]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 언어 선택 섹션
          Text(
            tr('language'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedLang,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedLang = value);
            },
            items: const [
              DropdownMenuItem(value: 'ko', child: Text('한국어')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
          ),
          const SizedBox(height: 24),
          // 자동응답 설정 섹션
          Text(
            tr('reply_to_all'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile.adaptive(
            value: _replyToAll,
            onChanged: (val) {
              setState(() => _replyToAll = val);
            },
            title: Text(_replyToAll ? tr('reply_to_all') : tr('reply_to_all')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: tr('default_message'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('languageCode', _selectedLang);
              await prefs.setBool('autoReplyToAll', _replyToAll);
              await prefs.setString('autoReplyMessage',
                  _messageController.text.trim());
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('settings_saved'))),
              );
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
            ),
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }
}
