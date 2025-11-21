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
      appBar: AppBar(title: const Text("Auto Reply Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Auto Reply 활성화"),
              value: provider.settings.enabled,
              onChanged: provider.enableAutoReply,
            ),
            const SizedBox(height: 16),

            // Auto reply message input
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Auto Reply Message",
                hintText: "예: 지금은 수면 중입니다. 나중에 연락드릴게요.",
              ),
              onChanged: provider.updateMessage,
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ContactFilterScreen()),
                  );
                },
                icon: const Icon(Icons.contacts),
                label: const Text("Manage Contacts"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
