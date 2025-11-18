// Android 에서 SMS 자동응답에 사용할 수 있는 서비스 뼈대 코드입니다.
// 실제 사용 시 telephony 패키지, 권한 설정이 필요합니다.

class SmsService {
  static Future<void> sendAutoReply({
    required String number,
    required String message,
  }) async {
    // TODO: telephony 패키지를 사용해 SMS 전송 구현
    // ex) telephony.sendSms(to: number, message: message);
  }
}
