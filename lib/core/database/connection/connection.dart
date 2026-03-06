// dart.library.html → 웹 빌드, dart.library.io → 네이티브 빌드
// 컴파일 타임에 플랫폼에 맞는 파일을 선택한다.
export 'native.dart' if (dart.library.html) 'web.dart';
