import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auto_reply_provider.dart';
import 'contact_filter_screen.dart';

/// AutoReplySettingsScreen allows the user to enable/disable auto reply,
/// set a custom reply message and manage a list of contacts to whom the
/// automatic reply should be sent.  The UI remains unchanged from the
/// original SleepPlanner app; additional logic is added to propagate
/// changes to the native Android side via a MethodChannel.
class AutoReplySettingsScreen extends StatelessWidget {
  const AutoReplySettingsScreen({super.key});

  // Channel used to communicate settings changes to Android.  The channel
  // name must match the name defined in MainActivity.
  static const MethodChannel _platform = MethodChannel('auto_reply_channel');

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AutoReplyProvider>(context);
    final controller = TextEditingController(text: provider.settings.replyMessage);

    return Scaffold(
      appBar: AppBar(title: const Text("Auto Reply Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Toggle auto reply on/off.  When changed, update provider and
            // notify the native side.
            SwitchListTile(
              title: const Text("Auto Reply 활성화"),
              value: provider.settings.enabled,
              onChanged: (value) {
                provider.enableAutoReply(value);
                _platform.invokeMethod('enableAutoReply', {
                  'enabled': value,
                  'message': provider.settings.replyMessage,
                  'contacts': provider.settings.allowedContacts,
                });
              },
            ),
            const SizedBox(height: 16),
            // Allow the user to edit the reply message.  Save changes to the
            // provider and propagate to Android via the channel.  Note that
            // onChanged fires for every keystroke; this is acceptable for
            // simple strings.
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Auto Reply Message",
                hintText: "예: 지금은 수면 중입니다. 나중에 연락드릴게요.",
              ),
              onChanged: (text) {
                provider.updateMessage(text);
                _platform.invokeMethod('updateMessage', {'message': text});
              },
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