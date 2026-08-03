import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nae_mo/core/platform/firebase_auth_platform.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_remote_data_source.dart';
import 'package:nae_mo/features/auth/data/datasources/firebase_auth_session_remote_data_source.dart';
import 'package:nae_mo/features/auth/data/datasources/unsupported_auth_session_remote_data_source.dart';
import 'package:nae_mo/features/auth/data/gateways/firebase_auth_gateway.dart';
import 'package:nae_mo/features/auth/data/gateways/google_sign_in_gateway.dart';
import 'package:nae_mo/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:nae_mo/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:nae_mo/features/auth/domain/usecases/auth_session_use_cases.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn(),
);

final firebaseAuthGatewayProvider = Provider<FirebaseAuthGateway>((ref) {
  return FirebaseAuthGatewayImpl(ref.watch(firebaseAuthProvider));
});

final googleSignInGatewayProvider = Provider<GoogleSignInGateway>((ref) {
  return GoogleSignInGatewayImpl(ref.watch(googleSignInProvider));
});

final authSessionRemoteDataSourceProvider =
    Provider<AuthSessionRemoteDataSource>((ref) {
  if (!supportsFirebaseAuth) {
    return const UnsupportedAuthSessionRemoteDataSource();
  }
  return FirebaseAuthSessionRemoteDataSource(
    ref.watch(firebaseAuthGatewayProvider),
    ref.watch(googleSignInGatewayProvider),
  );
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
