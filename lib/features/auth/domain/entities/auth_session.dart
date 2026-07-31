enum AuthProviderType {
  google,
  apple;

  static AuthProviderType? fromStorageValue(String? value) => switch (value) {
        'google' => AuthProviderType.google,
        'apple' => AuthProviderType.apple,
        _ => null,
      };
}

sealed class AuthSession {
  const AuthSession();
}

final class UnauthenticatedSession extends AuthSession {
  const UnauthenticatedSession();
}

final class AuthenticatedSession extends AuthSession {
  final AuthProviderType provider;

  const AuthenticatedSession(this.provider);
}
