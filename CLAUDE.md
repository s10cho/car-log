# CLAUDE.md

이 저장소에서 작업할 때 따르는 규칙.

## 무엇을 만드는가

개인 차량 유지보수 기록 앱 (Flutter, iOS + Android). 기능 개수보다 다음이 우선이다.

- 기존 기록 확인은 앱 실행 후 3초 이내
- 새 기록 저장은 약 10초 이내
- 홈은 약 1초 안에 로컬 데이터로 그린다 — 네트워크 응답을 기다리고 홈을 띄우지 않는다
- 네트워크 없이 정비 기록 CRUD와 교체 시기 계산이 모두 동작한다
- AI와 차량 연동은 선택 기능이며, 실패해도 수동 입력을 막지 않는다

## 개발 순서

Foundation → Slice 1 → Slice 2 → ... 순서대로 하나씩 한다. 전체를 한 번에 구현하지 않는다.

각 Slice는 다음을 모두 통과해야 끝난 것이다.

```
format → analyze → unit test → widget/integration test → build → 런타임 확인
```

테스트가 실패한 상태로 다음 Slice로 넘어가지 않는다. 로그를 보고 근본 원인을 고친다.

## 명령

```bash
flutter pub get
dart run build_runner build            # Drift 코드 생성 (스키마를 고쳤으면 필수)
dart format .
flutter analyze --fatal-infos
flutter test
flutter test integration_test          # 시뮬레이터/기기 필요
flutter run                            # DEV, --dart-define=APP_ENV=production 으로 PROD
```

생성 파일(`*.g.dart`)은 저장소에 커밋한다. CI가 재생성 결과와 diff를 비교한다.

## 구조

```
lib/
  app/
    bootstrap.dart      모든 진입점이 거치는 초기화 (로깅, 전역 에러 핸들러, ProviderScope)
    config/             AppEnvironment / AppConfig — 환경별로 달라지는 값
    navigation/         GoRouter, 라우트 상수, 바텀 네비게이션 셸
    theme/              Material 3 테마
  core/                 기능에 종속되지 않는 기반
    database/           Drift AppDatabase 와 테이블
    storage/            SecureStore (Keychain / Keystore)
    errors/             AppException 계층
    logging/            root logger 설정
  features/<feature>/
    data/               repository, 외부/DB 접근
    domain/             엔티티와 비즈니스 규칙 (필요할 때 생긴다)
    presentation/       위젯과 화면 상태
```

## 규칙

**로컬 우선.** Drift DB가 Single Source of Truth다. 위젯은 로컬 상태에서 그린다.
원격 API는 로컬 상태를 갱신할 뿐, UI가 원격 응답에 직접 의존하지 않는다.

**Repository는 값이 있을 때만.** 플러그인/드라이버 예외를 `AppException` 으로 바꿔 주는
경계로 쓴다. 통과만 하는 래퍼는 만들지 않는다.

**Provider는 직접 선언한다.** `riverpod_generator` 는 쓰지 않는다 (이유: docs/decisions.md).
provider는 그것이 만드는 대상 옆에 둔다 — repository provider는 repository 파일에.

**자격증명은 SecureStore에만.** API Key와 OAuth 토큰을 Drift, preferences, export 백업,
로그 어디에도 남기지 않는다. 영수증 원문도 로그에 찍지 않는다.

**저장소의 비밀 파일은 git-crypt로 암호화한다.** 저장소가 public이므로, 비밀 파일을
커밋하기 전에 `/.gitattributes` 에 패턴이 있는지 먼저 확인하고 `git-crypt status -e` 로
암호화 대상인지 검증한다. 패턴에 없는 파일은 평문으로 공개된다.

**추상화는 실제 사용처가 생긴 뒤에.** AI Provider 인터페이스처럼 핸드오프 문서가 명시한
경계만 미리 만든다. 그 외 일반화는 두 번째 구현체가 생길 때 한다.

**관련 없는 리팩터링을 하지 않는다.** 고치기 전에 주변 코드, 데이터 흐름, 테스트를 먼저 읽는다.

**Backend를 추가하지 않는다.** 안전하게 구현할 방법이 정말 없을 때만, 이유를 먼저 문서로
남기고 논의한다.

## 테스트에서 주의할 점

**`testWidgets` 안에서 Drift 스트림을 `await` 하지 않는다.** `await repo.watchX().first`
는 영원히 멈춘다 — 스트림이 기다리는 타이머를 테스트 바인딩이 쥐고 있기 때문이다.
Future를 돌려주는 읽기(`findById` 등)는 괜찮다. 위젯 테스트는 UI로 검증하고, 스트림
동작은 순수 단위 테스트에서 확인한다.

**위젯 테스트에서 `pumpAndSettle` 을 쓰지 않는다.** 화면이 DB를 여는 동안
`CircularProgressIndicator` 가 떠 있으면 애니메이션이 끝나지 않아 반환되지 않는다.
`test/support/test_app.dart` 의 `settle(tester)` 로 정해진 프레임 수만 진행시킨다.

**실제 파일 I/O 가 끼는 탭은 `tapAndAwaitIo` 로 한다.** 위젯 테스트는 가짜 시계를 쥐고
있어서, 탭이 시작한 `dart:io` 작업(영수증 파일 복사 등)이 그냥 `pump` 만으로는 끝나지
않는다. `tester.runAsync` 로 실제 이벤트 루프를 돌려야 한다.

**앱은 `buildTestApp()` 으로 띄운다.** 인메모리 DB와 DEV 설정을 주입해 준다. 오버라이드
없이 띄우면 실제 기기 DB를 열려고 하다가 실패한다.

## 검증 환경

로컬 런타임 확인은 **iOS Simulator**에서 한다. 이 머신에서 Android 에뮬레이터를 띄우지
않는다. Android는 빌드 통과까지만 로컬/CI에서 확인하고, 동작 확인이 필요하면
Firebase App Distribution 으로 배포해 실기기에서 한다.

## 아직 정해지지 않은 것

- 현대/기아 Connected Car OAuth를 Backend 없이 안전하게 쓸 수 있는지
- 차량번호 기반 차량 조회 API의 상용 사용 가능 여부
- Export 백업의 암호화 방식

세부 내용은 [docs/decisions.md](docs/decisions.md).
