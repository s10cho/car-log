# Car Log

개인 차량의 유지보수 기록을 빠르게 남기고 확인하는 Flutter 앱 (iOS / Android).

기능을 늘리는 것보다 다음 네 가지를 빠르게 하는 것이 목표다.

1. 지난 정비 기록 즉시 확인
2. 정비 직후 최소 입력으로 기록
3. 다음 교체 시기 자동 계산 및 알림
4. 가능한 차량에서는 주행거리 자동 연동

핵심 기능은 네트워크와 AI 없이 동작한다. 로컬 DB가 Single Source of Truth다.

## 요구 환경

| | 버전 |
| --- | --- |
| Flutter | 3.47.3 (stable) |
| Dart | 3.13.3 |
| iOS | 15.0 이상 |
| Android | API 26 (Android 8.0) 이상 |
| JDK | 17 이상 (Zulu 21 확인됨) |

## 시작하기

```bash
flutter pub get
dart run build_runner build          # Drift 코드 생성
flutter test
```

## 실행

환경은 `--dart-define=APP_ENV` 로 선택한다. 기본값은 `dev`다.

```bash
flutter run                                          # DEV
flutter run --dart-define=APP_ENV=production         # PRODUCTION
```

DEV와 PRODUCTION은 서로 다른 로컬 DB 파일(`car_log_dev` / `car_log`)을 쓴다.

## 검증

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
flutter test integration_test            # 시뮬레이터/기기 필요
```

로컬 런타임 검증은 iOS Simulator에서 한다. Android는 이 개발 머신에서 실행하지 않고
Firebase App Distribution으로 배포해 실기기에서 확인한다. 자세한 내용은
[docs/decisions.md](docs/decisions.md) 참고.

## 스크린샷

UI 를 바꿨으면 눈으로 확인한다.

```bash
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots_test.dart -d <device>
```

`build/screenshots/` 에 화면별 PNG 가 떨어진다.

## 비밀 관리

저장소는 public이다. 서명 키, Firebase 서비스 계정, `.env` 같은 비밀 파일은
**git-crypt로 암호화해서** 커밋한다. 대상 패턴은 [`.gitattributes`](.gitattributes)에 있다.

새로 clone한 뒤에는 잠금을 풀어야 한다.

```bash
git-crypt unlock ~/.config/git-crypt/car-log.key
git-crypt status -e     # 암호화 대상 파일 확인
```

키 파일은 저장소 밖(`~/.config/git-crypt/car-log.key`)에 있다. **잃어버리면 복구할 수
없으니 비밀번호 관리자에 백업할 것.** 자세한 내용은 [secrets/README.md](secrets/README.md).

## Android 배포

Android 는 이 개발 머신에서 실행하지 않고 Firebase App Distribution 으로 실기기에
배포해 확인한다.

```bash
./tool/distribute_android.sh
```

필요한 것:

- `git-crypt unlock` 으로 서명 키가 풀려 있을 것
- `~/.keys/sycho-mobile/play-service-account.json` (여러 앱이 공유하는 계정 단위 키,
  저장소에 복사하지 않는다)

| | |
| --- | --- |
| Firebase 프로젝트 | `sycho-app-507317` |
| App ID | `1:197519335220:android:f4e6c022de139930d0cf61` |
| 테스터 그룹 | `sycho-testers` |

GitHub Actions 의 **Distribute Android** 워크플로로도 돌릴 수 있다. 수동 트리거
전용이다 — push 마다 배포하면 테스터에게 계속 알림이 간다.

## 기능

- 차량 여러 대 등록·전환·삭제 (등록은 한 번에 하나씩 묻는 단계별 흐름)
- 3D 차량 (Kenney Car Kit, CC0) 10종 중 선택, 홈 차고에 렌더
- 관리 점수와 배지
- 정비 기록 작성·수정·삭제, 영수증 첨부(카메라/앨범/파일)
- 기본 정비 항목 10종 + 사용자 정의 항목, 항목별 교체주기(거리/기간/복합)
- 다음 교체 시기 자동 계산과 로컬 알림
- AI 영수증 분석 (Gemini / OpenAI, 선택 사항)
- JSON 백업 내보내기·복원

핵심 기능은 네트워크 없이 동작한다. 자세한 판단 근거는
[docs/decisions.md](docs/decisions.md) 참고.

## 구조

```
lib/
  app/        앱 껍데기 — 환경 설정, 네비게이션, 테마, bootstrap
  core/       기능에 종속되지 않는 기반 — DB, 보안 저장소, 에러, 로깅
  features/   기능별 data / domain / presentation
```

자세한 규칙은 [CLAUDE.md](CLAUDE.md), 확정된 기술 결정은
[docs/decisions.md](docs/decisions.md)에 있다.
