import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameCtrl = TextEditingController();
  String chronotype = 'neutral';
  double cafSens = 0.5;
  double lightSens = 0.5;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();

    if (doc.exists) {
      final profile = UserProfile.fromMap(doc.id, doc.data()!);
      setState(() {
        nameCtrl.text = profile.name;
        chronotype = profile.chronotype;
        cafSens = profile.cafSens;
        lightSens = profile.lightSens;
      });
    }
  }

  Future<void> _save() async {
    final profile = UserProfile(
      uid: widget.uid,
      name: nameCtrl.text,
      chronotype: chronotype,
      cafSens: cafSens,
      lightSens: lightSens,
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .set(profile.toMap(), SetOptions(merge: true));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: chronotype,
              decoration: const InputDecoration(
                labelText: 'Chronotype',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'morning', child: Text('Morning Person')),
                DropdownMenuItem(value: 'evening', child: Text('Night Owl')),
                DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
              ],
              onChanged: (v) => setState(() => chronotype = v ?? 'neutral'),
            ),
            const SizedBox(height: 16),
            Text('Caffeine Sensitivity: ${cafSens.toStringAsFixed(2)}'),
            Slider(
              value: cafSens,
              onChanged: (v) => setState(() => cafSens = v),
            ),
            const SizedBox(height: 16),
            Text('Light Sensitivity: ${lightSens.toStringAsFixed(2)}'),
            Slider(
              value: lightSens,
              onChanged: (v) => setState(() => lightSens = v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
