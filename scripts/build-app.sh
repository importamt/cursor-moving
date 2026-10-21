#!/bin/bash
# CursorMoving.app 번들을 build/ 에 생성한다.
# 사용법: ./scripts/build-app.sh [--install]   (--install: /Applications 로 복사)
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="CursorMoving"
APP="build/${APP_NAME}.app"

# Apple silicon + Intel 유니버설 바이너리
BUILD_ARGS=(-c release --arch arm64 --arch x86_64)
swift build "${BUILD_ARGS[@]}" --product "$APP_NAME"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# 서명 인증서: SIGN_IDENTITY 지정 > 키체인의 Developer ID / Apple Development 인증서 > ad-hoc
# 인증서로 서명하면 팀 ID 기준으로 식별되어 재빌드해도 손쉬운 사용 권한이 유지된다.
# ad-hoc 은 바이너리 해시 기준이라 재빌드마다 권한을 다시 허용해야 한다.
SIGN_IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning \
  | grep -m1 -E '"(Developer ID Application|Apple Development):' \
  | sed -E 's/.*"(.*)"/\1/' || true)}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

# 인증서 서명은 공증에 필요한 Hardened Runtime + 보안 타임스탬프를 함께 적용한다
SIGN_OPTIONS=()
if [[ "$SIGN_IDENTITY" != "-" ]]; then
  SIGN_OPTIONS=(--options runtime --timestamp)
fi

codesign --force --sign "$SIGN_IDENTITY" "${SIGN_OPTIONS[@]+"${SIGN_OPTIONS[@]}"}" --identifier com.imbotaem.cursormoving "$APP"
echo "서명: $SIGN_IDENTITY"

if [[ "${1:-}" == "--install" ]]; then
  rm -rf "/Applications/${APP_NAME}.app"
  cp -R "$APP" /Applications/
  echo "설치 완료: /Applications/${APP_NAME}.app"
else
  echo "빌드 완료: $APP"
fi
