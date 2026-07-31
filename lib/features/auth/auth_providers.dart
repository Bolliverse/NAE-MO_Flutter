import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_local_data_source.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_local_data_source_impl.dart';
import 'package:nae_mo/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:nae_mo/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:nae_mo/features/auth/domain/usecases/auth_session_use_cases.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesAsyncProvider = Provider<SharedPreferencesAsync>(
  (ref) => SharedPreferencesAsync(),
);

final authSessionLocalDataSourceProvider =
    Provider<AuthSessionLocalDataSource>((ref) {
  final preferences = ref.watch(sharedPreferencesAsyncProvider);
  return AuthSessionLocalDataSourceImpl(preferences);
});

final authSessionRepositoryProvider = Provider<AuthSessionRepository>((ref) {
  final localDataSource = ref.watch(authSessionLocalDataSourceProvider);
  return AuthSessionRepositoryImpl(localDataSource);
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
