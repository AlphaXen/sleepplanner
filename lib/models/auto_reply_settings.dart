class AutoReplySettings {
  /// Auto reply 기능 ON/OFF
  bool enabled;

  /// 사용자가 직접 입력하는 자동응답 메시지
  String replyMessage;

  /// 자동응답을 허용할 연락처 목록 (이름 또는 번호)
  List<String> allowedContacts;

  AutoReplySettings({
    this.enabled = false,
    this.replyMessage = "지금은 수면 중입니다. 나중에 연락드릴게요.",
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
