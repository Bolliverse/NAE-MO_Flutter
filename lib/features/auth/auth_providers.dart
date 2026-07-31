import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_remote_data_source.dart';
import 'package:nae_mo/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:nae_mo/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:nae_mo/features/auth/domain/usecases/auth_session_use_cases.dart';

final authSessionRemoteDataSourceProvider =
    Provider<AuthSessionRemoteDataSource>((ref) {
  throw StateError('Firebase authentication is not initialized.');
});

final authSessionRepositoryProvider = Provider<AuthSessionRepository>((ref) {
  final remoteDataSource = ref.watch(authSessionRemoteDataSourceProvider);
  return AuthSessionRepositoryImpl(remoteDataSource);
});

final restoreAuthSessionUseCaseProvider =
    Provider<RestoreAuthSessionUseCase>((ref) {
  final repository = ref.watch(authSessionRepositoryProvider);
  return RestoreAuthSessionUseCase(repository);
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  final repository = ref.watch(authSessionRepositoryProvider);
  return SignInUseCase(repository);
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  final repository = ref.watch(authSessionRepositoryProvider);
  return SignOutUseCase(repository);
});
