import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/domain/repositories/auth_session_repository.dart';

class RestoreAuthSessionUseCase {
  final AuthSessionRepository _repository;

  const RestoreAuthSessionUseCase(this._repository);

  Future<Result<AuthSession>> call() => _repository.restoreSession();
}

class SignInUseCase {
  final AuthSessionRepository _repository;

  const SignInUseCase(this._repository);

  Future<Result<AuthSession>> call(AuthProviderType provider) =>
      _repository.signIn(provider);
}

class SignOutUseCase {
  final AuthSessionRepository _repository;

  const SignOutUseCase(this._repository);

  Future<Result<AuthSession>> call() => _repository.signOut();
}
