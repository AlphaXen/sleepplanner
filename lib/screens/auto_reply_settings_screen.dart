import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auto_reply_provider.dart';
import 'contact_filter_screen.dart';

class AutoReplySettingsScreen extends StatelessWidget {
  const AutoReplySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AutoReplyProvider>(context);
    final controller =
        TextEditingController(text: provider.settings.replyMessage);

    return Scaffold(
      appBar: AppBar(
        title: const Text("자동응답 설정"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: SwitchListTile(
                title: const Text(
                  "Auto Reply 활성화",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                value: provider.settings.enabled,
                onChanged: provider.enableAutoReply,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "자동응답 메시지",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "예: 지금은 수면 중입니다. 나중에 연락드릴게요.",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: provider.updateMessage,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.contacts),
                label: const Text("자동응답 연락처 설정"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactFilterScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
