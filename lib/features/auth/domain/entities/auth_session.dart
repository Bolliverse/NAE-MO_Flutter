enum AuthProviderType {
  google,
  apple;
}

sealed class AuthSession {
  const AuthSession();
}

final class UnauthenticatedSession extends AuthSession {
  const UnauthenticatedSession();
}

final class AuthenticatedSession extends AuthSession {
  final String uid;
  final AuthProviderType provider;

  const AuthenticatedSession({required this.uid, required this.provider});
}
