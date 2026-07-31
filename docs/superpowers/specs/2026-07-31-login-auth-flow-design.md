# NAE MO 로그인 및 세션 흐름 설계

> 상태: 구현 승인됨
> 기준일: 2026-07-31
> 대상 브랜치: `codex/login-auth-flow`
> 대상 플랫폼: Android, iOS, Web

## 1. 목적

앱 최초 진입 시 로그인 상태를 복원하고, 로그인 정보가 없을 때만 로그인 화면을 보여준다. Google 또는 Apple 임시 로그인을 완료하면 기존 일력 화면으로 이동하며, 앱을 다시 시작해도 로그인 상태를 유지한다. 사용자가 로그아웃하면 저장된 세션을 제거하고 로그인 화면으로 돌아간다.

이번 구현은 실제 OAuth 연동 전의 제품 흐름과 아키텍처 경계를 확정하는 작업이다. 실제 OAuth 단계에서는 인증 저장소 구현만 교체하고 화면, UseCase, 상태, 라우터 계약을 유지한다.

## 2. 범위

### 포함

- `NAE MO` 텍스트 워드마크를 사용하는 로그인 화면
- `Google로 계속하기`, `Apple로 계속하기` 버튼
- 공급자 식별자를 사용하는 임시 로그인 세션
- 앱 시작 시 영속 세션 복원
- 인증 상태에 따른 GoRouter 접근 제어
- 로그인 성공 후 기존 `/calendar/day` 이동
- 일력 화면 상단 메뉴의 로그아웃 항목
- 세션 읽기, 쓰기, 삭제 실패 처리
- 단위 테스트, 위젯 테스트, 라우팅 테스트
- 로그인 화면 라이트/다크 모드와 로그인 후 화면의 실제 스크린샷
- 기존 테스트의 한국어 날짜 데이터 초기화와 로그인 자산 경로에 직접 관련된 기준 경고 정리

### 제외

- Google 또는 Apple OAuth SDK 연동
- 토큰, 이메일, 사용자 프로필 또는 개인정보 저장
- 브랜드 스플래시 화면과 전환 연출
- 회원가입, 계정 연결, 계정 삭제
- 백엔드 인증과 서버 세션 검증
- 캘린더 제품 화면의 재설계
- 기존 Riverpod 생성 코드 deprecation 일괄 정리

브랜드 스플래시는 후속 독립 PR에서 세션 복원 중의 최소 로딩 화면을 교체한다.

## 3. 설계 원칙

- Presentation은 저장소 구현을 직접 알지 않는다.
- ViewModel은 UseCase만 호출한다.
- Repository 인터페이스는 Domain에 두고 구현체는 Data에 둔다.
- LocalDataSource만 로컬 영속 저장 API를 사용한다.
- 저장소 밖으로 예외를 전달하지 않고 `Result<T>`와 `Failure`로 변환한다.
- 실제 인증이 없는 상태에서 토큰처럼 보이는 값을 만들지 않는다.
- 인증 경로와 캘린더 경로를 GoRouter 한 곳에서 보호한다.
- 화면은 모바일 우선 단일 컬럼이며 Web에서는 최대 폭만 제한한다.

## 4. 아키텍처

```text
LoginPage / CalendarShellPage 로그아웃 메뉴
                    |
                    v
               AuthViewModel
                    |
                    v
    RestoreSession / SignIn / SignOut UseCase
                    |
                    v
          AuthSessionRepository (Domain)
                    |
                    v
       AuthSessionRepositoryImpl (Data)
                    |
                    v
       AuthSessionLocalDataSource (Data)
                    |
                    v
        로컬 영속 저장소 API
```

### 4.1 Domain

`AuthProviderType`은 `google`과 `apple`만 허용한다. `AuthSession`은 선택된 공급자만 담으며 토큰이나 사용자 개인정보를 포함하지 않는다.

`AuthSessionRepository`는 아래 세 동작을 제공한다.

- 저장된 세션 복원
- 선택한 공급자로 임시 로그인
- 저장된 세션 삭제

각 동작은 별도 UseCase로 노출한다.

### 4.2 Data

LocalDataSource는 공급자 식별자 하나만 저장한다. 값이 없거나 지원하지 않는 값이면 세션 없음으로 처리한다. Repository 구현체는 저장 API 예외를 기존 `CacheFailure`로 변환한다.

실제 OAuth 구현 시에는 원격 인증과 안전한 자격 증명 저장을 담당하는 DataSource를 추가한다. 현재의 임시 공급자 값은 실제 토큰으로 승격하지 않는다.

### 4.3 Presentation

인증 상태는 다음 상태를 구분한다.

- `restoring`: 앱 시작 후 세션을 확인하는 중
- `unauthenticated`: 로그인 정보 없음
- `authenticated`: Google 또는 Apple 세션 있음

로그인 또는 로그아웃 요청 중에는 중복 동작을 막는 제출 상태를 별도로 가진다. 사용자에게 보여줄 실패 메시지는 상태에 포함하되 Domain/Data 예외 객체는 노출하지 않는다.

## 5. 라우팅 및 데이터 흐름

### 5.1 앱 시작

```text
앱 시작
  -> restoring
  -> 세션 복원 성공 + 공급자 있음: /calendar/day
  -> 세션 없음 또는 복원 실패: /login
```

세션 복원이 끝나기 전에는 중앙 진행 표시만 있는 최소 로딩 화면을 사용한다. 로그인 화면이 잠깐 나타났다 사라지는 현상을 허용하지 않는다.

### 5.2 로그인

```text
Google/Apple 버튼 탭
  -> 두 버튼 잠금
  -> SignInUseCase
  -> 공급자 저장
  -> authenticated 상태
  -> /calendar/day
```

저장에 실패하면 로그인 화면을 유지하고 버튼을 다시 활성화한다. 성공했다고 표시하거나 캘린더로 이동하지 않는다.

### 5.3 로그아웃

```text
일력 화면 상단 메뉴의 로그아웃 선택
  -> SignOutUseCase
  -> 공급자 삭제
  -> unauthenticated 상태
  -> /login
```

삭제에 실패하면 인증 상태를 유지하고 재시도 가능한 오류를 표시한다. 실제 삭제가 완료되기 전에 로그아웃됐다고 표시하지 않는다.

### 5.4 접근 제어

- 인증되지 않은 사용자가 캘린더 경로에 접근하면 `/login`으로 보낸다.
- 인증된 사용자가 `/login`에 접근하면 `/calendar/day`로 보낸다.
- 화면 전환은 `go` 방식으로 수행해 뒤로가기로 로그인 화면에 복귀하지 않는다.

## 6. 화면 설계

### 6.1 로그인 화면

- SafeArea 안에서 모바일 우선 단일 컬럼을 사용한다.
- 상단에 하이픈 없는 `NAE MO` 텍스트 워드마크를 표시한다.
- 로그인 필요성을 설명하는 짧은 안내 문구를 제공한다.
- 하단 영역에 Google, Apple 버튼을 같은 너비와 비슷한 시각적 비중으로 배치한다.
- Web에서는 콘텐츠 최대 폭만 제한하고 별도 데스크톱 레이아웃을 만들지 않는다.
- 라이트 테마와 다크 테마에서 공식 버튼 변형을 사용한다.
- 처리 중에는 선택한 버튼에 진행 상태를 표시하고 두 버튼 모두 다시 누를 수 없게 한다.
- 실패 메시지는 버튼 가까이에 표시하고 스크린 리더가 읽을 수 있게 한다.

### 6.2 공식 로그인 버튼

Google 버튼은 공식 컬러 `G` 자산을 사용하고, 공식 가이드가 허용하는 Continue with Google 계열의 현지화 문구, 색상, 테두리, 여백을 따른다. Google 로고를 직접 그리거나 변형하지 않는다. Google 버튼은 다른 로그인 수단보다 작거나 덜 눈에 띄게 만들지 않는다.

Apple 버튼은 공식 Apple 로고 자산을 사용하고, 검정 또는 흰색 계열의 직사각형 버튼과 Continue with Apple 계열의 현지화 문구를 사용한다. 로고나 제목에 임의 색상을 적용하지 않는다. Apple 버튼은 Google 버튼보다 작게 만들지 않는다.

공식 근거:

- Google Sign in branding: https://developers.google.com/identity/branding-guidelines
- Apple Sign in with Apple HIG: https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple

### 6.3 로그아웃

기존 `CalendarShellPage` AppBar의 점 세 개 메뉴에 `로그아웃`을 추가한다. 독립 아이콘을 하나 더 배치하지 않아 향후 상단 메뉴 확장과 충돌하지 않게 한다.

## 7. 오류 처리

- 세션 복원 실패: 무한 로딩을 피하고 비로그인 상태로 전환한다.
- 로그인 저장 실패: 로그인 화면을 유지하고 오류 메시지를 표시한다.
- 로그아웃 삭제 실패: 현재 인증 상태를 유지하고 재시도를 안내한다.
- 처리 중 중복 입력: 모든 인증 버튼과 로그아웃 동작을 잠근다.
- 지원하지 않는 공급자 값: 세션 없음으로 취급한다.
- 실제 OAuth 오류: 이번 범위에 포함하지 않는다.

## 8. 테스트 전략

### 8.1 단위 테스트

- 공급자 저장, 복원, 삭제
- 저장값 없음과 지원하지 않는 저장값
- DataSource 예외의 Failure 변환
- RestoreSession, SignIn, SignOut UseCase 결과 전달
- AuthViewModel의 restoring, unauthenticated, authenticated 전이
- 로그인/로그아웃 실패 시 상태 유지와 오류 메시지

### 8.2 위젯 및 라우팅 테스트

- 세션 없음: 로그인 화면 표시
- Google 로그인: 일력 화면 이동
- Apple 로그인: 일력 화면 이동
- 저장된 세션 있음: 앱 재생성 후 일력 화면 표시
- 비로그인 상태의 캘린더 접근: 로그인 화면으로 전환
- 로그인 상태의 `/login` 접근: 일력 화면으로 전환
- 로그아웃 성공: 로그인 화면으로 전환하고 세션 삭제
- 저장 실패: 로그인 화면 유지와 오류 표시
- 로그인 버튼 접근성 레이블, 비활성화, 진행 상태
- 기존 smoke test의 한국어 날짜 데이터 초기화

### 8.3 검증 명령

- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze --no-pub`
- `flutter test --no-pub`
- 플랫폼 실행 후 실제 화면 확인

기존 `main`의 Riverpod 생성 타입 deprecation은 이번 PR에서 늘리지 않되 일괄 수정하지 않는다. 분석 결과는 기준 상태와 비교해 새 오류나 경고가 없는지 확인한다.

## 9. 시각 증거와 PR 구성

실제 실행 화면을 아래 상태로 캡처한다.

- 로그인 화면 라이트 테마
- 로그인 화면 다크 테마
- 로그인 성공 후 기존 일력 화면

PR 번호가 정해진 뒤 `docs/design/evidence/pr-<번호>-login-auth/` 아래에 이미지 파일을 커밋하고 PR 본문에 직접 삽입한다. 계획 기준, 실제 화면, 이전 동작과 달라진 점, 의도적으로 유지한 동작, 검증 결과를 PR 본문에 적는다.

모든 소스, 테스트, 문서, 자산, 증거 이미지 파일은 파일 하나당 커밋 하나로 기록한다. 구현 diff가 하나의 인증 흐름으로 리뷰하기 어려운 크기가 되면 인증 기반과 로그인 UI를 별도 PR로 나눈다.

## 10. 승인된 후속 작업 경계

1. 이번 PR: 임시 영속 세션, 로그인 UI, 라우터 가드, 로그아웃
2. 후속 PR: 브랜드 스플래시와 전환 연출
3. 후속 PR: 실제 Google/Apple OAuth와 안전한 자격 증명 저장
