sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class NetworkException extends AppException {
  final int? statusCode;
  const NetworkException(super.message, {this.statusCode});
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode});
}

class CacheException extends AppException {
  const CacheException(super.message);
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = '인증이 필요합니다.']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = '요청한 리소스를 찾을 수 없습니다.']);
}
