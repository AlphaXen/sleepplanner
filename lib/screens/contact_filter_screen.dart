import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auto_reply_provider.dart';

class ContactFilterScreen extends StatelessWidget {
  const ContactFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AutoReplyProvider>(context);
    final allowed = provider.settings.allowedContacts;

    final controller = TextEditingController();

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
                    }

                    controller.clear();
                  },
                  child: const Text("Add"),
                )
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
