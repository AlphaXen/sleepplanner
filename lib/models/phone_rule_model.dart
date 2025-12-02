/// 전화번호 + 메시지 규칙 모델
class PhoneRule {
  final int? id;
  final String phone;
  final String message;

  PhoneRule({this.id, required this.phone, required this.message});

  Map<String, dynamic> toMap() => {
        'id': id,
        'phone': phone,
        'message': message,
      };

  factory PhoneRule.fromMap(Map<String, dynamic> map) => PhoneRule(
        id: map['id'] as int?,
        phone: map['phone'] as String,
        message: map['message'] as String,
      );
}

