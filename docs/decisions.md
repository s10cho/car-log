# 기술 결정 기록

Foundation(Slice 0) 단계에서 확정한 사항과 그 이유. 뒤집을 때는 이 문서를 함께 고친다.

## 확정

### 최소 OS: iOS 15.0 / Android API 26

핸드오프 문서의 정책은 "최신 안정 OS 중심, 유지보수 부담이 큰 구형 OS는 적극 제외"다.

- **iOS 15.0** — Flutter 3.47 / Xcode 26의 기본값이자 하한. 더 올려도 얻는 API가 없고,
  플러그인 호환 문제만 늘어난다.
- **Android 26 (8.0)** — Flutter 기본값 24에서 올렸다. 26부터 Notification Channel,
  Adaptive Icon, `java.time` 을 desugaring 없이 쓸 수 있다. 알림이 MVP 기능이라
  이 경계가 실제로 코드를 단순하게 만든다.

### 환경 분리는 `--dart-define`, 네이티브 flavor 없음

DEV / PRODUCTION 두 가지만 둔다. Android product flavor + iOS scheme 을 만들면
Xcode scheme, xcconfig, CI 매트릭스가 전부 두 배가 되는데, 지금 얻는 것은 앱을 두 개
동시에 설치하는 편의뿐이다.

대신 `AppConfig` 가 환경별 값을 들고 있고, DEV와 PRODUCTION은 **다른 로컬 DB 파일**을
쓴다. 개발 중 데이터가 실사용 데이터를 오염시키지 않는다.

동시 설치가 실제로 필요해지면 그때 flavor를 도입한다.

### 상태관리: Riverpod, 코드 생성 없음

`flutter_riverpod` 의 provider를 직접 선언한다. `riverpod_generator` / `riverpod_lint` 는
쓰지 않는다.

이유: `riverpod_lint` → `custom_lint` 가 `analyzer` 8.x 를 고정하는 바람에 drift, riverpod,
build_runner 가 모두 몇 버전씩 뒤로 묶였다. 명시적으로 선언한 provider는 생성 코드가 없어
읽기도 쉽다. build_runner는 Drift 하나만 쓴다.

### DB: Drift

Vehicle ↔ Maintenance ↔ MaintenanceType ↔ Reminder 는 관계형 모델이 자연스럽고,
Reactive Query와 Migration이 둘 다 필요하다.

`AppPreferences` 키/값 테이블 하나로 시작한다. 도메인 테이블은 Slice 1에서 추가한다.

### 자격증명은 Drift에 넣지 않는다

AI API Key, OAuth Access/Refresh Token은 `SecureStore`(Keychain / Keystore)에만 둔다.
Drift에도, 일반 preferences에도, export 백업에도 들어가지 않는다.

### 번들 ID: `com.s10cho.carlog`

`flutter create` 기본값은 iOS `com.s10cho.carLog`, Android `com.s10cho.car_log` 로 서로
달랐다. iOS 번들 ID에는 밑줄을 쓸 수 없으므로 양쪽을 소문자 한 단어로 통일했다.

### Android 검증은 Firebase App Distribution

개발 머신에서 Android 에뮬레이터를 돌리지 않는다. 로컬 런타임 검증은 iOS Simulator에서
하고, Android는 빌드가 통과하는지까지만 로컬/CI에서 확인한 뒤 Firebase App Distribution
으로 배포해 실기기에서 확인한다.

> Firebase 프로젝트와 서비스 계정은 아직 만들지 않았다. Android 배포를 실제로 돌리려면
> Firebase 프로젝트 ID와 App Distribution 용 서비스 계정 키가 필요하다.

## 미정 / 검증 필요

### Connected Car (현대·기아) 아키텍처

공식 API의 OAuth 흐름이 Client Secret을 요구하면 모바일 앱만으로는 안전하게 구현할 수
없다. PKCE / public client 지원 여부를 문서로 먼저 확인해야 한다. Backend가 필요하다는
결론이 나오면 Slice 7을 멈추고 이유를 기록한 뒤 논의한다. (핸드오프 문서 §17)

### 차량번호 기반 차량 조회

차량번호만으로 제조사/모델/연식을 조회하는 공개 API를 상용 서비스에서 쓸 수 있는지
확인 필요. VIN fallback을 전제로 설계한다.

### 백업 암호화

Export 백업 자체의 암호화 방식은 Threat Model을 정한 뒤 Slice 8에서 결정한다.
