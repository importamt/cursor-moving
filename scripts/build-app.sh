#!/bin/bash
# CursorMoving.app 번들을 build/ 에 생성한다.
# 사용법: ./scripts/build-app.sh [--install]   (--install: /Applications 로 복사)
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="CursorMoving"
APP="build/${APP_NAME}.app"

swift build -c release --product "$APP_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# ad-hoc 서명 (재빌드 시 macOS 권한을 다시 허용해야 할 수 있음)
codesign --force --sign - --identifier com.imbotaem.cursormoving "$APP"

if [[ "${1:-}" == "--install" ]]; then
  rm -rf "/Applications/${APP_NAME}.app"
  cp -R "$APP" /Applications/
  echo "설치 완료: /Applications/${APP_NAME}.app"
else
  echo "빌드 완료: $APP"
fi
