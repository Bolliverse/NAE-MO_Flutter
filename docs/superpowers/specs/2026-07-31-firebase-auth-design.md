# NAE MO Firebase Auth 설계

> 상태: 구현 승인됨
> 기준일: 2026-07-31
> 대상 브랜치: `codex/firebase-auth`
> 기준 브랜치: `origin/main` (`bc2ccf0`, 로그인 흐름 PR #4 병합본)
> 대상 플랫폼: Android, iOS
> Firebase 프로젝트: `naem-o`

## 1. 목적

기존 Google/Apple 임시 로그인을 실제 Firebase Authentication으로 교체한다. 이미 구현된 로그인 화면, ViewModel, UseCase, 라우터 가드, 로그아웃 메뉴는 유지하고 Data 계층의 인증 구현만 교체한다.

Android와 iOS 모두 Google 및 Apple 로그인을 제공한다. Firebase가 네이티브 인증 세션을 영속화하고 복원하며, 앱은 Firebase 사용자의 `uid`와 로그인 공급자만 Domain 세션에 노출한다.

## 2. 확정된 환경

- Flutter 3.24.5
- Dart 3.5.4
- Riverpod 2.6.1
- Firebase 프로젝트 ID: `naem-o`
- Android application ID: `com.bolliverse.todo.todo_project`
- iOS bundle ID: `com.bolliverse.todo.todoProject`
- Firebase에 Android/iOS 앱 등록 완료
- Firebase Authentication에서 Google/Apple 공급자 활성화 완료
- Android 디버그 서명키 SHA-1/SHA-256 등록 완료
- Apple Developer 설정과 실제 iOS 서명/기기 검증은 Apple 담당자가 PR 후속 체크리스트로 완료

의존성은 현재 Flutter/Dart SDK와 호환되는 최신 안정 버전을 `flutter pub add`로 해석하고 `pubspec.lock`에 고정한다. Firebase 공식 Flutter 설정 요구사항에 맞춰 Android 최소 API를 23, iOS deployment target을 15로 올린다.

## 3. 범위

### 포함

- `firebase_core`, `firebase_auth`, `google_sign_in` 도입
- FlutterFire CLI로 `naem-o`의 Android/iOS 앱 구성 생성
- Android/iOS 앱 식별자 변경
- 앱 시작 시 Firebase 초기화
- Google 계정 선택과 Firebase credential 로그인
- Firebase `AppleAuthProvider` 로그인
- Firebase 인증 세션 복원
- Firebase 및 Google SDK 로그아웃
- `AuthenticatedSession`에 Firebase `uid`와 공급자 보관
- 취소, 네트워크, 공급자 설정, 계정 오류의 사용자 메시지 처리
- Data/Repository/ViewModel/Widget 회귀 테스트
- Android debug 빌드 검증
- Apple 담당자용 PR 설정·검증 체크리스트

### 제외

- Web, Windows, macOS, Linux Firebase 로그인 지원
- 이메일/비밀번호, 익명, 전화번호 로그인
- Google/Apple 계정 연결 또는 자동 병합
- 사용자 프로필, 이메일, 토큰의 앱 저장
- 회원 탈퇴와 Apple 토큰 폐기
- Firebase Emulator 기반 소셜 로그인 E2E
- 백엔드 ID token 검증
- 캘린더 데이터의 Firebase 동기화

비대상 플랫폼에서는 Firebase를 초기화하지 않으며, 로그인 시 지원 플랫폼 안내를 반환한다. 기존 Flutter 테스트와 비대상 플랫폼 빌드가 Firebase 초기화 때문에 즉시 실패하지 않게 한다.

## 4. 설계 원칙

- Presentation과 Domain은 Firebase SDK 타입을 알지 않는다.
- 기존 `AuthSessionRepository`와 세 UseCase 계약을 유지한다.
- `SharedPreferences`의 `auth.provider` 값은 더 이상 인증 근거로 사용하지 않는다.
- Firebase SDK 예외는 Data 계층에서 앱의 `Failure`로 변환한다.
- 앱은 OAuth token, authorization code, email, display name을 영속 저장하지 않는다.
- 로그인 취소는 오류가 아니며 로그인 화면을 조용히 유지한다.
- 성공은 Firebase가 실제 `User`와 non-empty `uid`를 반환했을 때만 보고한다.
- 로그아웃 실패 시 Firebase의 실제 인증 상태와 UI 상태가 어긋나지 않게 작업 순서를 정한다.

## 5. 아키텍처

```text
LoginPage / CalendarShellPage
             |
             v
        AuthViewModel
             |
             v
Restore / SignIn / SignOut UseCase
             |
             v
  AuthSessionRepository (Domain)
             |
             v
 AuthSessionRepositoryImpl (Data)
             |
             v
 FirebaseAuthRemoteDataSource
       |              |
       v              v
 FirebaseAuth      GoogleSignIn
```

### 5.1 Domain

`AuthProviderType`은 `google`, `apple`을 유지한다. `AuthenticatedSession`은 다음 값만 가진다.

- `uid`: Firebase 사용자의 안정적인 식별자
- `provider`: 현재 로그인 공급자

토큰, 이메일, 이름, 사진 URL은 포함하지 않는다. 공급자 연결은 이번 범위가 아니므로 하나의 세션은 하나의 공급자만 표현한다.

### 5.2 DataSource

`AuthSessionLocalDataSource`와 `AuthSessionLocalDataSourceImpl`을 제거하고 `AuthSessionRemoteDataSource`를 추가한다.

RemoteDataSource의 책임은 다음과 같다.

- Firebase 인증 상태의 최초 값을 읽어 세션 복원
- Google SDK에서 ID token을 받고 Firebase credential로 교환
- `AppleAuthProvider`로 Firebase 로그인
- Google SDK 세션과 Firebase 세션 로그아웃
- Firebase `User.providerData`의 `google.com`, `apple.com`을 Domain 공급자로 변환
- SDK 예외를 앱 예외로 정규화

인증 취소는 nullable 결과로 표현한다. Repository는 이를 `UnauthenticatedSession` 성공으로 변환하므로 ViewModel이 오류를 표시하지 않는다.

### 5.3 Repository

Repository는 RemoteDataSource 결과를 Domain `AuthSession`으로 변환한다.

- 사용자 없음: `UnauthenticatedSession`
- 실제 Firebase 사용자 있음: `AuthenticatedSession(uid, provider)`
- 인증 취소: `UnauthenticatedSession`
- 인증/네트워크/설정 예외: `AuthFailure`

기존 `CacheFailure`는 인증 경로에서 사용하지 않는다. 로컬 저장 실패처럼 오해될 수 있는 메시지도 Firebase 인증 메시지로 교체한다.

### 5.4 Dependency Injection

`auth_providers.dart`는 Firebase와 Google SDK 인스턴스, RemoteDataSource, Repository를 조립한다. 테스트가 SDK 없이 동작하도록 기존 `authSessionRepositoryProvider` override 경계는 유지한다.

## 6. 데이터 흐름

### 6.1 앱 시작과 세션 복원

```text
main
  -> WidgetsFlutterBinding.ensureInitialized
  -> Android/iOS에서 Firebase.initializeApp
  -> 날짜 로케일 초기화
  -> ProviderScope / App
  -> authStateChanges().first
  -> user 없음: /login
  -> user 있음: uid/provider 매핑 -> /calendar/day
```

Firebase 공식 문서대로 `authStateChanges()`의 첫 이벤트를 사용한다. 리스너 등록 직후 현재 로그인 상태가 전달되므로 앱 시작 시 저장된 Firebase 세션이 결정될 때까지 기존 로딩 화면을 유지할 수 있다.

### 6.2 Google 로그인

```text
Google 버튼
  -> GoogleSignIn 초기화/계정 선택
  -> Google ID token
  -> GoogleAuthProvider.credential
  -> FirebaseAuth.signInWithCredential
  -> Firebase User(uid)
  -> authenticated -> /calendar/day
```

Google SDK가 취소를 반환하면 로그인 화면을 유지한다. ID token이 없거나 Firebase 사용자가 반환되지 않으면 성공으로 처리하지 않는다.

### 6.3 Apple 로그인

```text
Apple 버튼
  -> AppleAuthProvider
  -> FirebaseAuth.signInWithProvider
  -> Firebase User(uid)
  -> authenticated -> /calendar/day
```

Android의 Apple 로그인에는 Apple Services ID 및 Firebase OAuth 구성이 필요하다. iOS에는 Runner의 Sign in with Apple capability가 추가로 필요하다. 코드와 Xcode 프로젝트 설정은 이번 브랜치에 반영하지만 Apple Developer 포털 권한이 필요한 작업은 PR 체크리스트로 남긴다.

### 6.4 로그아웃

Google 사용자면 Google SDK 로그아웃을 먼저 실행한 뒤 Firebase에서 로그아웃한다. Google SDK 정리에 실패하면 Firebase 인증 상태를 유지하고 오류를 반환한다. Firebase 로그아웃에 실패해도 Firebase 사용자가 남아 있으므로 UI는 인증 상태를 유지한다. Apple 사용자는 Firebase 로그아웃만 수행한다.

## 7. 오류 처리

- 사용자 취소: 메시지 없이 로그인 화면 유지
- 네트워크 실패: `네트워크 연결을 확인하고 다시 시도해 주세요.`
- Google/Apple 공급자 미설정: `로그인 설정이 완료되지 않았습니다.`
- 계정 비활성화: `사용할 수 없는 계정입니다.`
- credential 충돌: `이미 다른 로그인 방법으로 등록된 계정입니다.`
- 지원하지 않는 플랫폼: `Google 및 Apple 로그인은 Android와 iOS에서 지원됩니다.`
- 알 수 없는 인증 오류: `로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.`
- 로그아웃 실패: 기존 인증 상태 유지와 재시도 안내

로그에 token, authorization code 또는 이메일을 남기지 않는다.

## 8. 플랫폼 설정

### 8.1 공통

- Firebase CLI와 FlutterFire CLI 설치
- `flutterfire configure`로 프로젝트 `naem-o`의 Android/iOS 앱 선택
- 생성된 `lib/firebase_options.dart`를 사용해 Firebase 초기화
- Firebase 구성 파일은 API key를 포함하지만 Firebase 공식 설명상 비밀 자격 증명이 아니므로 프로젝트 설정 산출물로 커밋

### 8.2 Android

- namespace/application ID를 `com.bolliverse.todo.todo_project`로 변경
- `MainActivity` package 및 경로를 동일하게 변경
- 최소 SDK 23 적용
- FlutterFire가 생성/다운로드한 Android Firebase 구성 적용
- 등록된 SHA-1/SHA-256으로 Google 로그인 확인
- Google 로그인과 Apple 웹 인증 흐름을 실제 Android 기기 또는 Google Play 포함 에뮬레이터에서 확인

### 8.3 iOS

- Runner bundle ID를 `com.bolliverse.todo.todoProject`로 변경
- deployment target 15 적용
- FlutterFire가 생성/다운로드한 iOS Firebase 구성 적용
- Google URL scheme을 iOS 구성에 추가
- Runner에 Sign in with Apple entitlement/capability 선언

Apple 담당자는 병합 전 다음 외부 설정을 확인한다.

- Apple Developer App ID `com.bolliverse.todo.todoProject`에 Sign in with Apple 활성화
- Android Apple 로그인에 사용하는 Services ID 생성 및 redirect URI 등록
- Firebase Apple 공급자에 Team ID, Key ID, private key, Services ID 적용
- Xcode Signing 팀과 provisioning profile 갱신
- 실제 iOS 기기에서 Apple 및 Google 로그인 검증

private key 파일과 값은 Git 또는 PR 본문에 올리지 않는다.

## 9. 테스트 전략

### 9.1 TDD 단위 테스트

- Firebase 사용자 없음 복원
- Google/Apple provider 매핑과 `uid` 보존
- 알 수 없는 공급자 거부
- Google/Apple 로그인 성공
- 로그인 취소의 조용한 비인증 결과
- Firebase/Google 예외의 `AuthFailure` 변환
- Google 로그아웃 순서와 실패 시 Firebase 세션 유지
- Apple/Firebase 로그아웃
- ViewModel의 기존 중복 탭 방지와 실패 상태 유지

SDK 정적 singleton은 얇은 adapter 뒤에 두어 DataSource 테스트에서 fake로 교체한다. Firebase 네트워크는 단위 테스트에서 호출하지 않는다.

### 9.2 회귀 테스트

- 세션 없음: 로그인 화면
- Google/Apple 성공: 캘린더 이동
- 세션 복원 중 로그인 화면 flash 없음
- 로그아웃: 로그인 화면 이동
- 취소: 오류 없음과 버튼 재활성화
- 실패: 한국어 오류와 로그인 화면 유지
- 로그인 버튼 접근성과 큰 글자 레이아웃 유지

### 9.3 검증 명령

- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze --no-pub`
- `flutter test --no-pub`
- `flutter build apk --debug --no-pub`
- 실제 Android 기기/에뮬레이터 Google 로그인
- 실제 Android 기기/에뮬레이터 Apple 로그인
- Apple 담당자의 macOS/Xcode iOS 빌드 및 실제 기기 Google/Apple 로그인

현재 작업 환경은 Windows이므로 iOS build/signing 성공을 주장하지 않는다.

## 10. PR 구성과 완료 조건

코드 완료 조건:

- Android/iOS 식별자와 Firebase 구성 반영
- 임시 SharedPreferences 인증 제거
- Google/Apple Firebase 로그인 구현
- Firebase 세션 복원과 로그아웃 구현
- 자동화 테스트, 분석, Android debug 빌드 통과
- token/authorization code/private key 미커밋 확인

외부 완료 조건:

- Apple 담당자 설정 항목을 PR 본문 체크리스트로 공개
- Android 실제 로그인 결과 기록
- iOS 실제 로그인은 담당자 확인 전 미검증으로 표시
- 미검증 Apple 설정을 구현 완료로 표현하지 않음

## 11. 공식 근거

- Firebase Flutter setup: https://firebase.google.com/docs/flutter/setup
- Firebase Auth Flutter start and auth state: https://firebase.google.com/docs/auth/flutter/start
- Firebase federated identity for Google and Apple: https://firebase.google.com/docs/auth/flutter/federated-auth
- Google Sign-In Flutter package: https://pub.dev/packages/google_sign_in
- Sign in with Apple configuration: https://firebase.google.com/docs/auth/ios/apple
