import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_local_data_source.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionLocalDataSourceImpl implements AuthSessionLocalDataSource {
  static const providerKey = 'auth.provider';

  final SharedPreferencesAsync _preferences;

  const AuthSessionLocalDataSourceImpl(this._preferences);

  @override
  Future<AuthProviderType?> readProvider() async {
    try {
      final value = await _preferences.getString(providerKey);
      return AuthProviderType.fromStorageValue(value);
    } on Object {
      throw const CacheException('로그인 정보를 불러오지 못했습니다.');
    }
  }

  @override
  Future<void> writeProvider(AuthProviderType provider) async {
    try {
      await _preferences.setString(providerKey, provider.name);
    } on Object {
      throw const CacheException('로그인 정보를 저장하지 못했습니다.');
    }
  }

  @override
  Future<void> clearProvider() async {
    try {
      await _preferences.remove(providerKey);
    } on Object {
      throw const CacheException('로그아웃하지 못했습니다.');
    }
  }
}
