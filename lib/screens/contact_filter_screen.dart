import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auto_reply_provider.dart';

/// ContactFilterScreen lets the user add or remove contacts that should
/// receive an automatic reply when they call.  After modifying the list,
/// the updated contacts are sent to the native side via MethodChannel so
/// Android can apply the same filter when receiving calls.
class ContactFilterScreen extends StatelessWidget {
  const ContactFilterScreen({super.key});

  // Channel name must match the name defined in MainActivity.
  static const MethodChannel _platform = MethodChannel('auto_reply_channel');

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AutoReplyProvider>(context);
    final allowed = provider.settings.allowedContacts;
    final controller = TextEditingController();

    // Helper to propagate updated contact list to native side.
    void _updateNativeContacts(List<String> contacts) {
      _platform.invokeMethod('updateContacts', {'contacts': contacts});
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Auto Reply Contacts")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Add new contact (name or number)",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    final updated = List<String>.from(allowed);
                    if (!updated.contains(text)) {
                      updated.add(text);
                      provider.updateContacts(updated);
                      _updateNativeContacts(updated);
                    }
                    controller.clear();
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: allowed.length,
              itemBuilder: (context, index) {
                final name = allowed[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      final updated = List<String>.from(allowed);
                      updated.remove(name);
                      provider.updateContacts(updated);
                      _updateNativeContacts(updated);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}