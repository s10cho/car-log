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

## 구조

```
lib/
  app/        앱 껍데기 — 환경 설정, 네비게이션, 테마, bootstrap
  core/       기능에 종속되지 않는 기반 — DB, 보안 저장소, 에러, 로깅
  features/   기능별 data / domain / presentation
```

자세한 규칙은 [CLAUDE.md](CLAUDE.md), 확정된 기술 결정은
[docs/decisions.md](docs/decisions.md)에 있다.
