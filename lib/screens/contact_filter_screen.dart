import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auto_reply_provider.dart';

class ContactFilterScreen extends StatelessWidget {
  const ContactFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AutoReplyProvider>(context);
    final allowed = provider.settings.allowedContacts;

    // 샘플 연락처 – 나중에 실제 디바이스 연락처로 교체 가능
    final sampleContacts = [
      "엄마",
      "형",
      "회사팀장",
      "010-1234-5678",
      "010-9876-5432",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("자동응답 연락처 설정"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sampleContacts.length,
        itemBuilder: (context, index) {
          final name = sampleContacts[index];
          final isSelected = allowed.contains(name);

          return Card(
            elevation: 0,
            child: ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.green : Colors.grey,
              ),
              title: Text(name),
              onTap: () {
                final updated = List<String>.from(allowed);
                if (isSelected) {
                  updated.remove(name);
                } else {
                  updated.add(name);
                }
                provider.updateContacts(updated);
              },
            ),
          );
        },
      ),
    );
  }
}
