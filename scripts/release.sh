#!/bin/bash
# Apple 공증을 거친 배포용 zip 을 build/ 에 만든다.
# 사전 준비(1회): xcrun notarytool store-credentials cursormoving-notary --apple-id <Apple ID> --team-id <Team ID>
# 사용법: ./scripts/release.sh   (NOTARY_PROFILE 로 키체인 프로필 이름 지정 가능)
set -euo pipefail
cd "$(dirname "$0")/.."

NOTARY_PROFILE="${NOTARY_PROFILE:-cursormoving-notary}"
VERSION="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)"
APP="build/CursorMoving.app"
ZIP="build/CursorMoving-${VERSION}.zip"

swift test
./scripts/build-app.sh

if ! codesign -dv "$APP" 2>&1 | grep -q "Authority=Developer ID Application"; then
  echo "공증하려면 Developer ID Application 인증서로 서명해야 합니다 (SIGN_IDENTITY 확인)" >&2
  exit 1
fi

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

# 오프라인에서도 Gatekeeper 가 확인할 수 있도록 공증 티켓을 앱에 붙인 뒤 다시 압축한다
xcrun stapler staple "$APP"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

spctl --assess --type execute --verbose "$APP"
echo "배포 파일: $ZIP"
