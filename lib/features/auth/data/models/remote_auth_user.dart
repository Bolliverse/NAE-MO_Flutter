import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

class RemoteAuthUser {
  final String uid;
  final AuthProviderType provider;

  const RemoteAuthUser({required this.uid, required this.provider});
}
