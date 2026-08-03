import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/auth/data/auth_error_messages.dart';

void main() {
  group('firebaseAuthMessage', () {
    test('maps known Firebase authentication codes', () {
      expect(
        firebaseAuthMessage('network-request-failed'),
        '네트워크 연결을 확인하고 다시 시도해 주세요.',
      );
      expect(
        firebaseAuthMessage('operation-not-allowed'),
        '로그인 설정이 완료되지 않았습니다.',
      );
      expect(
        firebaseAuthMessage('user-disabled'),
        '사용할 수 없는 계정입니다.',
      );
      expect(
        firebaseAuthMessage('account-exists-with-different-credential'),
        '이미 다른 로그인 방법으로 등록된 계정입니다.',
      );
    });

    test('uses the generic message for an unknown code', () {
      expect(
        firebaseAuthMessage('unrecognized-code'),
        '로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    });
  });

  test('recognizes user-cancellation codes only', () {
    expect(isFirebaseCancellationCode('web-context-cancelled'), isTrue);
    expect(isFirebaseCancellationCode('canceled'), isTrue);
    expect(isFirebaseCancellationCode('cancelled'), isTrue);
    expect(isFirebaseCancellationCode('network-request-failed'), isFalse);
    expect(isFirebaseCancellationCode('operation-not-allowed'), isFalse);
  });
}
