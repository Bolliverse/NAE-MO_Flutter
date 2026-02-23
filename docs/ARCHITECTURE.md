# NAE-MO 아키텍처 및 설계 문서

> 최종 업데이트: 2026-02-23

---

## 목차

1. [기술 스택](#1-기술-스택)
2. [전체 아키텍처 개요](#2-전체-아키텍처-개요)
3. [MVVM + Riverpod Notifier](#3-mvvm--riverpod-notifier)
4. [Clean Architecture 레이어](#4-clean-architecture-레이어)
5. [Repository 패턴](#5-repository-패턴)
6. [DataSource 분리](#6-datasource-분리)
7. [UseCase (Command 패턴)](#7-usecase-command-패턴)
8. [DTO / Domain Entity 분리](#8-dto--domain-entity-분리)
9. [Mapper (Assembler)](#9-mapper-assembler)
10. [Result + Failure 모델](#10-result--failure-모델)
11. [폴더 구조](#11-폴더-구조)
12. [전체 데이터 흐름](#12-전체-데이터-흐름)
13. [라우팅 (GoRouter)](#13-라우팅-gorouter)
14. [네트워킹 (Dio + Retrofit)](#14-네트워킹-dio--retrofit)
15. [코드 생성 (build_runner)](#15-코드-생성-build_runner)
16. [코딩 컨벤션](#16-코딩-컨벤션)

---

## 1. 기술 스택

### 환경

| 항목 | 버전 |
|------|------|
| Flutter | 3.24.5 |
| Dart | 3.5.4 |
| 플랫폼 | Android / iOS / Web |
| 기본 폰트 | Pretendard (Variable) |

### 핵심 패키지

| 분류 | 패키지 | 역할 |
|------|--------|------|
| **상태관리** | `flutter_riverpod ^2.5.1` | ViewModel(Notifier) 기반 상태관리 |
| **상태관리 코드생성** | `riverpod_annotation ^2.3.5` | `@riverpod` 어노테이션 |
| **라우팅** | `go_router ^14.6.2` | 선언형 라우팅 |
| **네트워크** | `dio ^5.8.0` | HTTP 클라이언트 |
| **API 클라이언트** | `retrofit ^4.4.1` | type-safe REST API |
| **데이터 클래스** | `freezed_annotation ^2.4.2` | DTO 불변 클래스 |
| **JSON 직렬화** | `json_annotation ^4.9.0` | JSON 파싱 |
| **로컬 저장소** | `shared_preferences ^2.3.3` | 일반 설정값 저장 |
| **보안 저장소** | `flutter_secure_storage ^9.2.4` | 토큰 등 민감 데이터 |
| **동등성 비교** | `equatable ^2.0.7` | Failure 값 비교 |
| **로깅** | `logger ^2.5.0` | 구조화된 로그 출력 |
| **국제화** | `intl ^0.19.0` | 날짜/통화 포맷 |
| **SVG** | `flutter_svg ^2.0.16` | SVG 이미지 렌더링 |
| **이미지 캐시** | `cached_network_image ^3.4.1` | 네트워크 이미지 캐싱 |

### 폰트

| 폰트 | 파일 | 방식 |
|------|------|------|
| Pretendard | `assets/fonts/PretendardVariable.ttf` | Variable Font (단일 파일로 전 굵기 지원) |

Variable Font이므로 파일 하나로 `FontWeight.w100` ~ `FontWeight.w900` 전체를 사용할 수 있다.

```yaml
# pubspec.yaml
fonts:
  - family: Pretendard
    fonts:
      - asset: assets/fonts/PretendardVariable.ttf
```

```dart
// 사용 예 — fontFamily 명시 없이 theme의 fontFamily가 자동 적용됨
Text('안녕하세요', style: TextStyle(fontWeight: FontWeight.w600))
```

### 개발 도구 (dev_dependencies)

| 패키지 | 역할 |
|--------|------|
| `build_runner ^2.4.13` | 코드 생성 실행기 |
| `riverpod_generator ^2.4.3` | Riverpod Provider/Notifier 코드 생성 |
| `freezed ^2.4.7` | DTO 불변 클래스 코드 생성 |
| `json_serializable ^6.8.0` | fromJson/toJson 코드 생성 |
| `retrofit_generator ^8.2.1` | Retrofit API 구현체 코드 생성 |
| `flutter_lints ^4.0.0` | 린트 규칙 |

---

## 2. 전체 아키텍처 개요

MVVM과 Clean Architecture를 결합한다.
**MVVM**은 UI 레이어의 관심사 분리를 담당하고,
**Clean Architecture**는 전체 레이어(Presentation / Domain / Data)의 의존성 방향을 제어한다.

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                  │
│                                                      │
│   View (Widget)  ──►  ViewModel (Notifier)          │
│        │                    │                        │
│        │ UI 이벤트 전달       │ UseCase 호출           │
└────────┼────────────────────┼────────────────────────┘
         │                    │
         │             ┌──────▼──────────────────────┐
         │             │       DOMAIN LAYER           │
         │             │                              │
         │             │   UseCase ──► Repository     │
         │             │               (interface)    │
         │             └───────────────────┬──────────┘
         │                                 │
         │                    ┌────────────▼───────────┐
         │                    │       DATA LAYER        │
         │                    │                         │
         │                    │  Repository (impl)      │
         │                    │       │                 │
         │                    │  Mapper/Assembler        │
         │                    │       │                 │
         │                    │  DataSource             │
         │                    │  (Remote / Local)       │
         └────────────────────┴─────────────────────────┘

의존성 방향: Presentation → Domain ← Data
```

---

## 3. MVVM + Riverpod Notifier

### 개념

| MVVM 역할 | 이 프로젝트에서 | 역할 |
|-----------|---------------|------|
| **View** | `ConsumerWidget` / `ConsumerStatefulWidget` | UI 렌더링, 사용자 이벤트 수신 |
| **ViewModel** | Riverpod `Notifier` / `AsyncNotifier` | UI 상태 보유, UseCase 호출, 결과 변환 |
| **Model** | Domain Entity + UseCase + Repository | 비즈니스 데이터 및 로직 |

### 핵심 원칙

- **View는 상태를 직접 변경하지 않는다.** ViewModel(Notifier)의 메서드를 호출할 뿐이다.
- **ViewModel은 UI 상태만 안다.** 네트워크나 DB를 직접 호출하지 않고 UseCase에 위임한다.
- **ViewModel이 보유하는 상태는 UI State 객체** 하나다. 여러 필드를 흩뿌리지 않는다.

### UI State 정의

ViewModel이 관리하는 상태는 feature별 State 클래스로 정의한다.

```dart
// presentation/states/user_state.dart
@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default(AsyncValue.loading()) AsyncValue<User> user,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _UserState;
}
```

### ViewModel (Notifier) 작성 패턴

```dart
// presentation/viewmodels/user_viewmodel.dart
part 'user_viewmodel.g.dart';

@riverpod
class UserViewModel extends _$UserViewModel {
  @override
  UserState build(String userId) {
    // 초기 상태 정의 후 데이터 로드
    _loadUser(userId);
    return const UserState();
  }

  // ── 이벤트 처리 메서드 (View에서 호출) ──────────────
  Future<void> _loadUser(String userId) async {
    state = state.copyWith(user: const AsyncValue.loading());

    final useCase = ref.read(getUserUseCaseProvider);
    final result = await useCase(userId);

    result.fold(
      onSuccess: (user) {
        state = state.copyWith(user: AsyncValue.data(user));
      },
      onFailure: (failure) {
        state = state.copyWith(
          user: AsyncValue.error(failure.message, StackTrace.current),
        );
      },
    );
  }

  Future<void> refresh(String userId) => _loadUser(userId);
}
```

### View (Widget) 작성 패턴

```dart
// presentation/pages/user_page.dart
class UserPage extends ConsumerWidget {
  const UserPage({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태 구독
    final state = ref.watch(userViewModelProvider(userId));

    return Scaffold(
      body: state.user.when(
        data: (user) => _UserBody(user: user),
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Text(e.toString()),
      ),
      // 이벤트 → ViewModel 메서드 호출
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref
            .read(userViewModelProvider(userId).notifier)
            .refresh(userId),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

### View ↔ ViewModel 규칙 요약

```
View → ViewModel : notifier.메서드() 호출만 한다
ViewModel → View : state를 변경하면 자동으로 rebuild된다
View는 state를 직접 수정하지 않는다
ViewModel은 BuildContext를 받지 않는다
```

---

## 4. Clean Architecture 레이어

의존성은 항상 **Domain 방향(안쪽)** 으로만 흐른다.

```
Presentation  ──►  Domain  ◄──  Data
```

### Presentation 레이어

- View(Widget), ViewModel(Notifier), UI State
- Domain의 UseCase만 호출한다
- Data 레이어를 직접 import하지 않는다

### Domain 레이어

- Entity, UseCase, Repository 인터페이스
- Flutter SDK 포함 **외부 패키지를 import하지 않는다** (순수 Dart)
- 이 레이어는 어떤 것도 의존하지 않는다 — 테스트가 가장 쉽다

### Data 레이어

- Repository 구현체, DataSource, DTO, Mapper
- Domain의 Repository 인터페이스를 구현한다
- Presentation을 알지 못한다

---

## 5. Repository 패턴

### 역할

Data 레이어와 Domain 레이어 사이의 **경계**다.
Domain은 인터페이스만 알고, 실제 데이터 출처(API, DB)를 모른다.

### 인터페이스 (Domain 레이어)

```dart
// domain/repositories/user_repository.dart
abstract interface class UserRepository {
  Future<Result<User>> getUser(String id);
  Future<Result<List<User>>> getUsers();
  Future<Result<User>> createUser(CreateUserParams params);
  Future<Result<void>> deleteUser(String id);
}
```

### 구현체 (Data 레이어)

```dart
// data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remote;
  final UserLocalDataSource _local;
  final UserMapper _mapper;

  const UserRepositoryImpl({
    required UserRemoteDataSource remote,
    required UserLocalDataSource local,
    required UserMapper mapper,
  })  : _remote = remote,
        _local = local,
        _mapper = mapper;

  @override
  Future<Result<User>> getUser(String id) async {
    try {
      final dto = await _remote.getUser(id);
      return success(_mapper.toEntity(dto));
    } on UnauthorizedException catch (e) {
      return fail(const UnauthorizedFailure());
    } on NetworkException catch (e) {
      return fail(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return fail(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }
}
```

### Riverpod Provider 등록

```dart
// data/repositories/user_repository_provider.dart
@riverpod
UserRepository userRepository(Ref ref) => UserRepositoryImpl(
  remote: ref.read(userRemoteDataSourceProvider),
  local: ref.read(userLocalDataSourceProvider),
  mapper: const UserMapper(),
);
```

### Repository 규칙

- **반환 타입은 항상 `Result<T>`** — 절대 throw하지 않는다
- DataSource의 `AppException`을 catch하여 `Failure`로 변환하는 책임을 진다
- 캐시 전략(remote 실패 시 local fallback 등)을 담당한다
- Mapper를 통해 DTO → Entity 변환한다 (직접 변환 로직을 쓰지 않는다)

---

## 6. DataSource 분리

### 역할

실제 데이터 I/O를 수행하는 최하위 레이어다.
**Remote**(네트워크)와 **Local**(로컬 저장소)을 분리한다.

### Remote DataSource

```dart
// domain/datasources/user_remote_data_source.dart  ← 인터페이스
abstract interface class UserRemoteDataSource {
  Future<UserDto> getUser(String id);
  Future<List<UserDto>> getUsers();
  Future<UserDto> createUser(CreateUserDto dto);
}

// data/datasources/user_remote_data_source_impl.dart  ← 구현
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final UserApi _api;
  const UserRemoteDataSourceImpl(this._api);

  @override
  Future<UserDto> getUser(String id) async {
    try {
      return await _api.getUser(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException e) {
    return switch (e.response?.statusCode) {
      401 => const UnauthorizedException(),
      404 => const NotFoundException(),
      _ => NetworkException(e.message ?? '네트워크 오류'),
    };
  }
}
```

### Local DataSource

```dart
// data/datasources/user_local_data_source_impl.dart
class UserLocalDataSourceImpl implements UserLocalDataSource {
  final SharedPreferences _prefs;
  const UserLocalDataSourceImpl(this._prefs);

  @override
  Future<UserDto?> getCachedUser(String id) async {
    final json = _prefs.getString('user_$id');
    if (json == null) return null;
    return UserDto.fromJson(jsonDecode(json));
  }
}
```

### DataSource 규칙

- **throw만 한다** — `Result<T>` 반환하지 않음. 예외를 `AppException`으로 변환하여 throw
- Remote는 `DioException` → `AppException` 변환 책임을 진다
- Local은 `CacheException` throw
- DTO를 반환한다 (Entity 변환은 하지 않는다)

---

## 7. UseCase (Command 패턴)

### 개념

**하나의 클래스 = 하나의 비즈니스 동작.**
Command 패턴으로 각 동작을 독립된 객체로 캡슐화한다.

### 네이밍 규칙

```
동사 + 명사 + UseCase
GetUserUseCase       ← 조회
CreateOrderUseCase   ← 생성
UpdateProfileUseCase ← 수정
DeleteCommentUseCase ← 삭제
```

### 작성 패턴

```dart
// domain/usecases/get_user_use_case.dart
class GetUserUseCase {
  final UserRepository _repository;
  const GetUserUseCase(this._repository);

  // call()을 사용하면 useCase(id) 형태로 호출 가능
  Future<Result<User>> call(String id) => _repository.getUser(id);
}
```

파라미터가 복잡한 경우 Params 객체를 별도로 정의한다.

```dart
// domain/usecases/create_user_use_case.dart
class CreateUserUseCase {
  final UserRepository _repository;
  const CreateUserUseCase(this._repository);

  Future<Result<User>> call(CreateUserParams params) =>
      _repository.createUser(params);
}

// domain/usecases/create_user_params.dart
class CreateUserParams {
  final String name;
  final String email;
  const CreateUserParams({required this.name, required this.email});
}
```

### Riverpod Provider 등록

```dart
// domain/usecases/get_user_use_case.dart (하단에 추가)
@riverpod
GetUserUseCase getUserUseCase(Ref ref) =>
    GetUserUseCase(ref.read(userRepositoryProvider));
```

### ViewModel에서 사용

```dart
// ViewModel 내부
final result = await ref.read(getUserUseCaseProvider)('user-123');
// 또는 call() 덕분에 이렇게도 가능
final useCase = ref.read(getUserUseCaseProvider);
final result = await useCase('user-123');
```

### UseCase 규칙

- 메서드는 `call()` 하나만 가진다
- Repository 인터페이스에만 의존한다 (DataSource 직접 접근 금지)
- 반환 타입은 `Future<Result<T>>` 또는 `Result<T>`
- 상태를 가지지 않는다 (모든 필요한 값은 파라미터로 받는다)
- 비즈니스 로직(유효성 검사, 조합 등)이 필요한 경우 여기서 처리한다

---

## 8. DTO / Domain Entity 분리

### 분리 이유

| | DTO | Domain Entity |
|--|-----|--------------|
| **위치** | Data 레이어 | Domain 레이어 |
| **역할** | API 응답 구조 표현 | 비즈니스 개념 표현 |
| **의존성** | `freezed`, `json_annotation` | 없음 (순수 Dart) |
| **변경 이유** | API 스펙 변경 | 비즈니스 규칙 변경 |

API 스펙이 바뀌어도 Domain Entity와 비즈니스 로직은 영향받지 않는다.

### DTO 작성 (Data 레이어)

```dart
// data/models/user_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
class UserDto with _$UserDto {
  const factory UserDto({
    required String id,
    required String name,
    required String email,
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
}
```

### Domain Entity 작성 (Domain 레이어)

```dart
// domain/entities/user.dart

// 외부 패키지 import 없음 — 순수 Dart
class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
  });
}
```

### 파일명 규칙

```
DTO:    user_dto.dart         (suffix: _dto)
Entity: user.dart             (suffix 없음, 개념 자체의 이름)
Params: create_user_params.dart
```

---

## 9. Mapper (Assembler)

### 역할

DTO ↔ Domain Entity 변환을 담당하는 **별도 클래스**.
Repository 안에 변환 로직을 직접 쓰지 않는다.

### 위치

```
data/
└── mappers/
    └── user_mapper.dart
```

### 작성 패턴

```dart
// data/mappers/user_mapper.dart
import 'package:nae_mo/data/models/user_dto.dart';
import 'package:nae_mo/domain/entities/user.dart';

class UserMapper {
  const UserMapper();

  // DTO → Entity (Data → Domain 방향)
  User toEntity(UserDto dto) => User(
        id: dto.id,
        name: dto.name,
        email: dto.email,
        profileImageUrl: dto.profileImageUrl,
        createdAt: DateTime.parse(dto.createdAt),
      );

  // Entity → DTO (Domain → Data 방향, 요청 생성 시 사용)
  UserDto toDto(User entity) => UserDto(
        id: entity.id,
        name: entity.name,
        email: entity.email,
        profileImageUrl: entity.profileImageUrl,
        createdAt: entity.createdAt.toIso8601String(),
      );

  // 리스트 변환
  List<User> toEntityList(List<UserDto> dtos) =>
      dtos.map(toEntity).toList();
}
```

### Mapper 규칙

- **상태 없는 순수 변환 클래스** — `const` 생성자 사용
- Repository 생성자에서 주입받는다
- Entity → DTO 변환(`toDto`)은 요청 Body 생성 시에만 사용한다
- 변환 중 타입 파싱(`DateTime.parse` 등)이 실패하면 `CacheException` throw

---

## 10. Result + Failure 모델

### 설계 의도

Repository 이상의 레이어는 **절대 throw하지 않는다.**
성공과 실패를 하나의 타입(`Result<T>`)으로 표현하여 처리를 강제한다.

### Failure (lib/core/errors/failure.dart)

비즈니스 실패를 나타내는 `sealed class`. `equatable`로 값 비교 가능.

```dart
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '네트워크 연결을 확인해주세요.']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = '데이터를 불러올 수 없습니다.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = '인증이 필요합니다.']);
}
```

### Result\<T\> (lib/core/utils/result.dart)

Dart record 타입을 활용한 경량 Result 타입.

```dart
typedef Result<T> = ({T? data, Failure? failure});

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => failure == null && data != null;
  bool get isFailure => failure != null;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    if (isSuccess) return onSuccess(data as T);
    return onFailure(failure!);
  }
}

Result<T> success<T>(T data) => (data: data, failure: null);
Result<T> fail<T>(Failure failure) => (data: null, failure: failure);
```

### AppException (lib/core/errors/app_exception.dart)

DataSource에서 발생하는 내부 예외. Data 레이어 밖으로 나가지 않는다.

```dart
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class NetworkException extends AppException { ... }
class ServerException extends AppException { ... }
class UnauthorizedException extends AppException { ... }
class NotFoundException extends AppException { ... }
class CacheException extends AppException { ... }
```

### 레이어별 에러 처리 흐름

```
DataSource
  DioException 발생
  → AppException으로 변환하여 throw
        ↓
Repository
  AppException을 catch
  → Failure로 변환
  → Result.fail(failure) 반환
        ↓
UseCase
  Result<T>를 그대로 반환
        ↓
ViewModel (Notifier)
  result.fold(
    onSuccess: → state 업데이트,
    onFailure: → 에러 state 업데이트,
  )
        ↓
View (Widget)
  state를 보고 UI 렌더링
```

### Failure → UI 처리 패턴

```dart
// ViewModel 내부
result.fold(
  onSuccess: (user) {
    state = state.copyWith(user: AsyncValue.data(user));
  },
  onFailure: (failure) {
    // sealed class 패턴 매칭
    final message = switch (failure) {
      UnauthorizedFailure() => '로그인이 필요합니다.',
      NetworkFailure()      => '인터넷 연결을 확인해주세요.',
      ServerFailure()       => '서버 오류가 발생했습니다.',
      _                     => failure.message,
    };
    state = state.copyWith(errorMessage: message);
  },
);
```

---

## 11. 폴더 구조

```
lib/
├── main.dart                          # 진입점 — ProviderScope
├── app.dart                           # MaterialApp.router + 테마
│
├── core/                              # 전체 앱 공통 인프라
│   ├── constants/
│   │   └── app_constants.dart         # 앱 이름, baseUrl, 키 상수
│   ├── errors/
│   │   ├── app_exception.dart         # DataSource 예외 (sealed class)
│   │   └── failure.dart               # Repository 이상 실패 타입 (sealed class)
│   ├── network/
│   │   └── dio_client.dart            # Dio 인스턴스 + 인터셉터
│   ├── router/
│   │   └── app_router.dart            # GoRouter 설정
│   ├── theme/
│   │   └── app_theme.dart             # 라이트/다크 테마
│   └── utils/
│       └── result.dart                # Result<T> 타입
│
├── features/
│   └── [feature_name]/                # 예: user, auth, order
│       │
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── user_remote_data_source.dart       # 인터페이스
│       │   │   ├── user_remote_data_source_impl.dart  # 구현체 (Retrofit)
│       │   │   ├── user_local_data_source.dart        # 인터페이스
│       │   │   └── user_local_data_source_impl.dart   # 구현체 (SharedPrefs)
│       │   ├── mappers/
│       │   │   └── user_mapper.dart                   # DTO ↔ Entity 변환
│       │   ├── models/
│       │   │   └── user_dto.dart                      # API DTO (freezed)
│       │   └── repositories/
│       │       ├── user_repository_impl.dart          # Repository 구현체
│       │       └── user_repository_provider.dart      # Riverpod Provider
│       │
│       ├── domain/
│       │   ├── entities/
│       │   │   └── user.dart                          # Domain Entity (순수 Dart)
│       │   ├── repositories/
│       │   │   └── user_repository.dart               # Repository 인터페이스
│       │   └── usecases/
│       │       ├── get_user_use_case.dart
│       │       ├── create_user_use_case.dart
│       │       └── params/
│       │           └── create_user_params.dart
│       │
│       └── presentation/
│           ├── pages/
│           │   └── user_page.dart                     # View (ConsumerWidget)
│           ├── viewmodels/
│           │   └── user_viewmodel.dart                # ViewModel (Notifier)
│           ├── states/
│           │   └── user_state.dart                    # UI State (freezed)
│           └── widgets/
│               └── user_card.dart                     # 기능 전용 위젯
│
└── shared/
    ├── widgets/                                       # 앱 공통 UI 컴포넌트
    └── models/                                        # 앱 공통 모델
```

> 이전의 `presentation/providers/` 폴더는 **`viewmodels/`** 와 **`states/`** 로 분리한다.
> Notifier = ViewModel, State 클래스 = 별도 파일로 관리한다.

---

## 12. 전체 데이터 흐름

### 읽기 (Query) 흐름 예시: 사용자 조회

```
1. View
   UserPage가 렌더링되며 userViewModelProvider를 watch

2. ViewModel (Notifier.build)
   build() 호출 → _loadUser() 실행
   ref.read(getUserUseCaseProvider) 로 UseCase 획득

3. UseCase
   GetUserUseCase.call(id) 실행
   → UserRepository.getUser(id) 호출

4. Repository (impl)
   UserRemoteDataSource.getUser(id) 호출
   성공 시: UserMapper.toEntity(dto) → success(entity) 반환
   실패 시: AppException → Failure → fail(failure) 반환

5. DataSource (Remote)
   UserApi.getUser(id) 호출 (Retrofit)
   DioException → AppException 변환 후 throw

6. 결과 역방향 전파
   Result<User> → UseCase → ViewModel
   ViewModel: result.fold()로 state 업데이트

7. View
   state 변경 감지 → rebuild → UI 반영
```

### 쓰기 (Command) 흐름 예시: 사용자 생성

```
1. View
   버튼 탭 → notifier.createUser(name, email) 호출

2. ViewModel
   state = state.copyWith(isSubmitting: true)
   CreateUserUseCase.call(CreateUserParams(...)) 실행

3. UseCase → Repository → DataSource → API

4. ViewModel
   result.fold()
   성공 → isSubmitting: false, 완료 처리 (예: 화면 이동)
   실패 → isSubmitting: false, errorMessage 설정

5. View
   isSubmitting으로 로딩 표시
   errorMessage로 에러 스낵바 표시
```

---

## 13. 라우팅 (GoRouter)

### 설정 위치

`lib/core/router/app_router.dart` — Riverpod Provider로 관리

### 라우트 추가 방법

```dart
GoRoute(
  path: '/users/:id',
  name: 'userDetail',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return UserPage(userId: id);
  },
),
```

### 화면 이동

```dart
// 이름으로 이동 (권장)
context.goNamed('userDetail', pathParameters: {'id': '123'});

// 스택에 추가 (뒤로가기 가능)
context.pushNamed('userDetail', pathParameters: {'id': '123'});
```

### 인증 가드

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = ref.read(authStateProvider).isLoggedIn;
    if (!isLoggedIn && state.matchedLocation != '/login') return '/login';
    return null;
  },
)
```

---

## 14. 네트워킹 (Dio + Retrofit)

### Dio 인터셉터

| 인터셉터 | 역할 |
|----------|------|
| `LogInterceptor` | 요청/응답 로그 (개발 환경) |
| `_AuthInterceptor` | 요청 헤더 토큰 주입, 401 시 토큰 갱신 |

### Retrofit API 정의

```dart
// data/datasources/user_api.dart
part 'user_api.g.dart';

@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String? baseUrl}) = _UserApi;

  @GET('/users/{id}')
  Future<UserDto> getUser(@Path('id') String id);

  @POST('/users')
  Future<UserDto> createUser(@Body() UserDto body);
}
```

---

## 15. 코드 생성 (build_runner)

### 코드 생성이 필요한 경우

| 어노테이션 | 생성 파일 |
|-----------|-----------|
| `@riverpod` (함수/클래스) | `파일명.g.dart` |
| `@freezed` | `파일명.freezed.dart` + `파일명.g.dart` |
| `@JsonSerializable` | `파일명.g.dart` |
| `@RestApi` | `파일명.g.dart` |

### 파일 상단 선언 규칙

```dart
// @riverpod만 사용하는 경우
part 'user_viewmodel.g.dart';

// @freezed + @JsonSerializable 사용하는 경우 (DTO, State)
part 'user_dto.freezed.dart';
part 'user_dto.g.dart';
```

### 실행 명령어

```bash
# 한 번 생성
dart run build_runner build --delete-conflicting-outputs

# 변경 감지 모드 (개발 중 권장)
dart run build_runner watch --delete-conflicting-outputs
```

### .gitignore 정책

`.g.dart`, `.freezed.dart` 파일은 커밋하지 않는다.
각 개발자가 `build_runner build`를 실행하여 로컬에서 생성한다.

---

## 16. 코딩 컨벤션

### 파일/폴더 네이밍

| 대상 | 규칙 | 예시 |
|------|------|------|
| 파일 | `snake_case` | `user_repository_impl.dart` |
| 클래스 | `PascalCase` | `UserRepositoryImpl` |
| 변수/함수 | `camelCase` | `getUserUseCase` |
| DTO suffix | `_dto` | `UserDto`, `user_dto.dart` |
| ViewModel suffix | `ViewModel` | `UserViewModel` |
| UseCase suffix | `UseCase` | `GetUserUseCase` |
| Mapper suffix | `Mapper` | `UserMapper` |
| State suffix | `State` | `UserState` |
| Params suffix | `Params` | `CreateUserParams` |

### import 규칙

```dart
// ❌ 상대경로 금지
import '../../core/errors/failure.dart';

// ✅ package 경로 사용 (analysis_options.yaml 강제 설정)
import 'package:nae_mo/core/errors/failure.dart';
```

### ref 사용 규칙

```dart
// ✅ build() 내부 → ref.watch() (상태 구독, 변경 시 rebuild)
final state = ref.watch(someProvider);

// ✅ 이벤트 핸들러 / Notifier 메서드 내부 → ref.read() (일회성 읽기)
onPressed: () => ref.read(someProvider.notifier).doSomething();
```

### 금지 사항

- `BuildContext`를 ViewModel(Notifier) 내부로 전달하지 않는다
- Domain Entity에 `package:flutter` import 금지
- Data 레이어에서 Presentation 레이어 import 금지
- Domain 레이어에서 Data 레이어 import 금지
- Repository에서 직접 DTO ↔ Entity 변환 로직 작성 금지 (Mapper 사용)
- UseCase에 여러 개의 public 메서드 금지 (Command 패턴)
- ViewModel에서 DataSource 또는 API 직접 호출 금지 (UseCase 경유)
