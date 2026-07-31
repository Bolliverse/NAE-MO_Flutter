const genericAuthErrorMessage = '로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.';

String firebaseAuthMessage(String code) => switch (code) {
      'network-request-failed' => '네트워크 연결을 확인하고 다시 시도해 주세요.',
      'operation-not-allowed' ||
      'invalid-credential' ||
      'invalid-oauth-provider' =>
        '로그인 설정이 완료되지 않았습니다.',
      'user-disabled' => '사용할 수 없는 계정입니다.',
      'account-exists-with-different-credential' => '이미 다른 로그인 방법으로 등록된 계정입니다.',
      _ => genericAuthErrorMessage,
    };

bool isFirebaseCancellationCode(String code) => const {
      'web-context-cancelled',
      'canceled',
      'cancelled',
    }.contains(code);
