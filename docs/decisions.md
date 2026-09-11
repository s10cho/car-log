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

### 기본 정비 항목의 주기는 일반 권장값이다

`lib/core/database/built_in_maintenance_types.dart` 에 10개 항목을 심는다. 이 중 스펙이
수치를 명시한 것은 엔진오일(10,000 km 또는 12개월)과 와이퍼(12개월) 둘뿐이고, 나머지
8개는 국내 승용차에서 통용되는 범위를 골랐다. 제조사 수치가 아니다.

지어낸 값을 진실처럼 보이게 두지 않기 위해 두 가지를 한다. 항목 관리 화면에 "일반적인
권장값"이라고 적고, 앱 전체 기본값과 차량별 override를 모두 수정 가능하게 둔다.

시드는 `code` 로 중복을 판단하는 `insertOrIgnore` 라서, 사용자가 고친 이름이나 주기를
앱 업데이트가 되돌리지 않는다.

### 홈은 기록이 있는 항목만 보여준다

기본 항목 10개를 전부 나열하면 새 차량의 홈이 "기록 없음" 아홉 줄에 묻힌다. 홈은 이
차량에서 실제로 기록한 항목만 급한 순(지남 → 임박 → 여유)으로 보여주고, 전체 목록은
항목 관리 화면에서 본다.

### 기본 항목은 삭제할 수 없다

이름과 주기는 고칠 수 있지만 삭제는 사용자 정의 항목만 가능하다. 정비 기록이 항목을
참조하므로 삭제는 이력을 함께 날리거나 실패한다. 참조가 있는 사용자 정의 항목도
삭제를 막고 기록이 몇 건인지 알려 준다.

### Android 검증은 Firebase App Distribution

개발 머신에서 Android 에뮬레이터를 돌리지 않는다. 로컬 런타임 검증은 iOS Simulator에서
하고, Android는 빌드가 통과하는지까지만 로컬/CI에서 확인한 뒤 Firebase App Distribution
으로 배포해 실기기에서 확인한다.

Firebase 프로젝트 `sycho-app-507317` 과 서비스 계정
`play-publisher@sycho-app-507317.iam.gserviceaccount.com` 을 다른 프로젝트와 공유한다.
서비스 계정 키는 **저장소에 복사하지 않고** 계정 공통 경로
`~/.keys/sycho-mobile/play-service-account.json` 을 `GOOGLE_APPLICATION_CREDENTIALS` 로
가리킨다. 사본을 만들면 키를 교체할 때 프로젝트를 전부 고쳐야 하고, 하나를 빠뜨리면
그 앱만 조용히 실패한다. CI 에서는 같은 키를 GitHub Secret 으로 넣는다.

> 남은 작업: Firebase 콘솔에서 `com.s10cho.carlog` 앱을 등록하고 App ID 를 받는 것.

### 비밀 파일은 git-crypt (대칭키)

저장소가 public이므로 서명 키, Firebase 서비스 계정, `.env` 는 암호화해서 커밋한다.
`.gitignore` 로 빼는 대신 git-crypt를 쓰는 이유는, 파일이 버전 관리 안에 남아 있어야
CI가 쓸 수 있고 기기를 바꿔도 따라오기 때문이다.

GPG 대신 대칭키를 쓴다. 1인 프로젝트라 키 배포 대상이 없고, CI에는 base64로 인코딩한
키 하나를 GitHub Secret에 넣으면 끝난다. GPG 키링 관리 비용만 늘어난다.

한계: 암호문의 **파일 이름과 크기는 공개된다.** 이름에 정보를 담지 않는다.
키는 `~/.config/git-crypt/car-log.key` 에 있고 저장소에는 들어가지 않는다.
키를 잃으면 암호화된 파일은 복구 불가다.

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
