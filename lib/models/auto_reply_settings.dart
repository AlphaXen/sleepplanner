class AutoReplySettings {
  /// Auto reply feature ON/OFF
  bool enabled;

  /// Custom auto-reply message entered by user
  String replyMessage;

  /// List of contacts allowed for auto-reply (name or number)
  List<String> allowedContacts;

  AutoReplySettings({
    this.enabled = false,
    this.replyMessage = "I'm currently sleeping. I'll get back to you later.",
    this.allowedContacts = const [],
  });

  AutoReplySettings copyWith({
    bool? enabled,
    String? replyMessage,
    List<String>? allowedContacts,
  }) {
    return AutoReplySettings(
      enabled: enabled ?? this.enabled,
      replyMessage: replyMessage ?? this.replyMessage,
      allowedContacts: allowedContacts ?? this.allowedContacts,
    );
  }
}
