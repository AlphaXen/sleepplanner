import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/phone_rule_model.dart';
import '../services/rules_db.dart';

class RulesPage extends StatefulWidget {
  const RulesPage({super.key});

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  static const platform = MethodChannel('com.example.call/autoreply');

  List<PhoneRule> _rules = [];
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = [
      Permission.phone,
      Permission.sms,
    ];

    for (var permission in permissions) {
      if (!await permission.isGranted) {
        await permission.request();
      }
    }
  }

  Future<void> _loadRules() async {
    final rules = await RulesDb.instance.getRules();
    setState(() {
      _rules = rules;
    });
  }

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

  Future<void> _addOrEditRule({PhoneRule? rule}) async {
    final phoneController = TextEditingController(text: rule?.phone ?? '');
    final msgController = TextEditingController(text: rule?.message ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(rule == null ? 'Add Auto Reply Rule' : 'Edit Auto Reply Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Phone Number',
                    hintText: 'e.g., +1234567890',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: msgController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Auto Reply Message',
                    hintText: 'Message to send when this number calls...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
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
    final phonePermission = await Permission.phone.status;
    final smsPermission = await Permission.sms.status;

    if (!phonePermission.isGranted || !smsPermission.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone and SMS permissions required')),
      );
      await _checkPermissions();
      return;
    }

    try {
      await _syncRulesToPrefs();
      await platform.invokeMethod('startService');
      setState(() => _isServiceRunning = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auto Reply service started')),
      );
    } catch (e) {
      debugPrint('Failed to start service: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start service: $e')),
      );
    }
  }

  Future<void> _stopService() async {
    try {
      await platform.invokeMethod('stopService');
      setState(() => _isServiceRunning = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auto Reply service stopped')),
      );
    } catch (e) {
      debugPrint('Failed to stop service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Reply Rules'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Service Status Card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isServiceRunning 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isServiceRunning 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isServiceRunning ? Icons.check_circle : Icons.cancel,
                      color: _isServiceRunning ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isServiceRunning ? 'Service Running' : 'Service Stopped',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isServiceRunning ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isServiceRunning ? null : _startService,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isServiceRunning ? _stopService : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Restart service after editing rules',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Rules List
          Expanded(
            child: _rules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rule,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No auto reply rules',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add a rule',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rules.length,
                    itemBuilder: (context, index) {
                      final rule = _rules[index];
                      return ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(
                          rule.phone,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          rule.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _addOrEditRule(rule: rule),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteRule(rule),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditRule(),
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
    );
  }
}
