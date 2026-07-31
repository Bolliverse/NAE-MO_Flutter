import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

class AuthState {
  final AuthSession session;
  final bool isSubmitting;
  final AuthProviderType? pendingProvider;
  final String? errorMessage;

  const AuthState({
    required this.session,
    this.isSubmitting = false,
    this.pendingProvider,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthSession? session,
    bool? isSubmitting,
    AuthProviderType? pendingProvider,
    bool clearPendingProvider = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AuthState(
      session: session ?? this.session,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pendingProvider:
          clearPendingProvider ? null : pendingProvider ?? this.pendingProvider,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}
