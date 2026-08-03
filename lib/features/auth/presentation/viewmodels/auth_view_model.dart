import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/auth/auth_providers.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/presentation/states/auth_state.dart';

final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);

class AuthViewModel extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    try {
      final result = await ref.read(restoreAuthSessionUseCaseProvider)();
      return result.fold(
        onSuccess: (session) => AuthState(session: session),
        onFailure: (failure) => AuthState(
          session: const UnauthenticatedSession(),
          errorMessage: failure.message,
        ),
      );
    } on Object {
      return const AuthState(
        session: UnauthenticatedSession(),
        errorMessage: '로그인 정보를 확인하지 못했습니다.',
      );
    }
  }

  Future<void> signIn(AuthProviderType provider) async {
    final current = state.asData?.value;
    if (current == null || current.isSubmitting) return;

    state = AsyncData(
      current.copyWith(
        isSubmitting: true,
        pendingProvider: provider,
        clearErrorMessage: true,
      ),
    );

    try {
      final result = await ref.read(signInUseCaseProvider)(provider);
      state = AsyncData(_resolve(result, current));
    } on Object {
      state = AsyncData(
        _failed(current, '로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.'),
      );
    }
  }

  Future<void> signOut() async {
    final current = state.asData?.value;
    if (current == null || current.isSubmitting) return;

    state = AsyncData(
      current.copyWith(
        isSubmitting: true,
        clearPendingProvider: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final result = await ref.read(signOutUseCaseProvider)();
      state = AsyncData(_resolve(result, current));
    } on Object {
      state = AsyncData(
        _failed(current, '로그아웃하지 못했습니다. 다시 시도해 주세요.'),
      );
    }
  }

  AuthState _resolve(Result<AuthSession> result, AuthState previous) {
    return result.fold(
      onSuccess: (session) => AuthState(session: session),
      onFailure: (failure) => _failed(previous, failure.message),
    );
  }

  AuthState _failed(AuthState previous, String message) {
    return previous.copyWith(
      isSubmitting: false,
      clearPendingProvider: true,
      errorMessage: message,
    );
  }
}
