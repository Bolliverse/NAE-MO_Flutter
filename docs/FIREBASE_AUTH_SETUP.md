# Firebase Auth 설정 및 검증

NAE-MO는 Firebase Authentication으로 Android와 iOS에서 Google 및 Apple 로그인을 제공한다.

## 등록 정보

- Firebase 프로젝트: `naem-o`
- Android application ID: `com.bolliverse.todo.todo_project`
- iOS bundle ID: `com.bolliverse.todo.todoProject`
- Firebase 설정 파일:
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`

Firebase 설정 파일은 앱 식별용 구성이다. Apple private key, Firebase CLI 로그인 토큰, 사용자 인증 토큰은 저장소에 커밋하지 않는다.

## 개발 환경 준비

1. Flutter 의존성을 설치한다.

   ```shell
   flutter pub get
   ```

2. Android 디버그 빌드를 확인한다.

   ```shell
   flutter build apk --debug --no-pub
   ```

3. iOS는 macOS/Xcode에서 CocoaPods 의존성을 설치한 뒤 Runner workspace를 연다.

   ```shell
   cd ios
   pod install
   open Runner.xcworkspace
   ```

## Android 확인 체크리스트

- [x] Firebase Android 앱의 package name이 `com.bolliverse.todo.todo_project`인지 확인
- [x] Firebase Android 앱에 개발용 SHA-1 및 SHA-256 등록
- [x] Firebase Authentication에서 Google 및 Apple 공급자 활성화
- [ ] 실제 Android 기기에서 Google 로그인 확인
- [ ] 실제 Android 기기에서 Apple 로그인 확인

SHA 인증서를 새 개발 PC나 배포 키로 변경하면 해당 SHA-1/SHA-256을 Firebase Android 앱에 추가하고 `google-services.json`을 다시 받아야 한다.

## Apple 담당자 체크리스트

- [ ] Apple Developer App ID `com.bolliverse.todo.todoProject`에서 Sign in with Apple 활성화
- [ ] Android Apple 로그인을 위한 Services ID 생성
- [ ] Return URL에 `https://naem-o.firebaseapp.com/__/auth/handler` 등록
- [ ] Firebase Authentication Apple 공급자에 Services ID, Team ID, Key ID, private key 설정
- [ ] Xcode Runner target의 Team 및 provisioning profile 갱신
- [ ] 실제 iOS 기기에서 Google 로그인 확인
- [ ] 실제 iOS 기기에서 Apple 로그인 확인

private key 파일과 값은 Git, 이슈, PR 본문에 첨부하지 않는다.

Apple Developer 설정을 마친 뒤 Xcode의 Runner target에서 `Sign in with Apple` capability와 `Runner/Runner.entitlements`가 연결되어 있는지 확인한다. 저장소에는 entitlement 선언이 포함되어 있지만 Team 및 provisioning profile은 Apple 계정 권한이 있는 담당자가 갱신해야 한다.

## 현재 검증 범위

- Windows에서 Dart 정적 분석 및 전체 Flutter 테스트 실행
- Windows에서 Android debug APK 빌드
- PowerShell XML/프로젝트 검사로 iOS bundle ID, Firebase plist 리소스, Google URL scheme, Apple entitlement, iOS 15 deployment target 확인
- macOS/Xcode 빌드와 Android/iOS 실제 공급자 로그인은 담당자 실기기 검증 필요
