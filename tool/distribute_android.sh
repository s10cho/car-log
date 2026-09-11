#!/usr/bin/env bash
# Builds a release APK and hands it to Firebase App Distribution.
#
# Credentials come from a service account key that lives outside this
# repository and is shared with the other apps in the same Firebase project.
# Copying it in would mean fixing every project when the key is rotated, and
# missing one would fail quietly.
set -euo pipefail

FIREBASE_PROJECT="${FIREBASE_PROJECT:-sycho-app-507317}"
FIREBASE_APP_ID="${FIREBASE_APP_ID:-1:197519335220:android:f4e6c022de139930d0cf61}"
TESTER_GROUP="${TESTER_GROUP:-sycho-testers}"
CREDENTIALS="${GOOGLE_APPLICATION_CREDENTIALS:-$HOME/.keys/sycho-mobile/play-service-account.json}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ ! -f "$CREDENTIALS" ]]; then
  echo "서비스 계정 키가 없습니다: $CREDENTIALS" >&2
  echo "GOOGLE_APPLICATION_CREDENTIALS 로 경로를 지정하거나 키를 그 자리에 두세요." >&2
  exit 1
fi

# An unsigned-by-us build would install for testers but could never be updated
# by a properly signed one, so refuse rather than distribute a dead end.
if [[ ! -f android/key.properties ]]; then
  echo "android/key.properties 가 없습니다. git-crypt 잠금을 먼저 푸세요:" >&2
  echo "  git-crypt unlock ~/.config/git-crypt/car-log.key" >&2
  exit 1
fi

notes_file="$(mktemp)"
trap 'rm -f "$notes_file"' EXIT
{
  echo "${RELEASE_NOTES:-$(git log -1 --pretty=%s)}"
  echo
  echo "commit $(git rev-parse --short HEAD)"
} > "$notes_file"

echo "==> flutter build apk --release"
flutter build apk --release

apk=build/app/outputs/flutter-apk/app-release.apk
echo "==> 배포: $apk → $TESTER_GROUP"
GOOGLE_APPLICATION_CREDENTIALS="$CREDENTIALS" \
  firebase appdistribution:distribute "$apk" \
    --app "$FIREBASE_APP_ID" \
    --groups "$TESTER_GROUP" \
    --release-notes-file "$notes_file" \
    --project "$FIREBASE_PROJECT"
