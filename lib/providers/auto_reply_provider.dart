import 'package:flutter/material.dart';
import '../models/auto_reply_settings.dart';

class AutoReplyProvider extends ChangeNotifier {
  AutoReplySettings settings = AutoReplySettings();

  void enableAutoReply(bool value) {
    settings = settings.copyWith(enabled: value);
    notifyListeners();
  }

  void updateMessage(String msg) {
    settings = settings.copyWith(replyMessage: msg);
    notifyListeners();
  }

  void updateContacts(List<String> contacts) {
    settings = settings.copyWith(allowedContacts: contacts);
    notifyListeners();
  }
}
