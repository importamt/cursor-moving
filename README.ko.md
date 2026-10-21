# CursorMoving

키보드와 마우스를 한동안 쓰지 않으면 커서로 도형을 부드럽게 그리고 제자리로 돌려놓는 macOS 메뉴바 앱입니다.

[English](README.md)

## 기능

- **유휴 감지**: 키보드·마우스 입력이 5초 / 10초 / 15초 / 30초(기본) / 1분 / 5분 동안 없을 때만 동작
- **모양**: 지그재그 / 동그라미 / 네모 / 별을 약 2초에 걸쳐 부드럽게 그림
- **방해하지 않음**: 그리는 중에 마우스를 움직이거나 키를 누르면 즉시 멈추고, 커서는 출발한 자리로 돌아옴
- **전역 단축키**: `⌃⌥⌘M`으로 켜기/끄기 (변경 가능)
- **환경설정**: 로그인 시 자동 실행, 앱 시작 시 켜기, English / 한국어, 단축키
- 네트워크 접속이나 데이터 수집 없음

## 설치

1. [**Releases**](https://github.com/importamt/cursor-moving/releases/latest)에서 최신 `CursorMoving-x.y.z.zip`을 받습니다.
2. 압축을 풀고 `CursorMoving.app`을 `응용 프로그램` 폴더로 옮깁니다.
3. `CursorMoving.app`을 실행하면 메뉴바에 커서 아이콘이 생깁니다 (Dock 아이콘은 없습니다).
4. 안내가 나오면 **손쉬운 사용** 권한을 허용합니다.
   **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용 → CursorMoving** 켜기.
   macOS에서 커서를 움직이는 앱은 모두 이 권한이 필요합니다.

Developer ID로 서명하고 Apple 공증을 받은 앱이라 Gatekeeper 경고 없이 열립니다.

**요구 사항**: macOS 13 Ventura 이상 (Apple silicon, Intel)

## 사용법

메뉴바 아이콘을 누르세요. 처음 언어는 English이고, **Settings… → Language**에서 한국어로 바꿀 수 있습니다.

| 메뉴 | 설명 |
|------|------|
| 커서 이동 켜기 / 끄기 | 켜고 끄기 (`⌃⌥⌘M`) |
| 유휴 감지 | 입력이 없을 때 얼마나 기다렸다가 그릴지 |
| 모양 | 지그재그 / 동그라미 / 네모 / 별 |
| 설정… | 환경설정 열기 (`⌘,`) |

켜져 있는 동안 아이콘이 초록색으로 바뀝니다.

### 환경설정

- **일반**: 로그인 시 자동 실행, 앱 시작 시 커서 이동 켜기
- **언어**: English(기본) / 한국어
- **단축키**: **변경…**을 누르고 새 키 조합(예: `⌘⌥O`)을 누른 뒤 **확인**.
  `⌘`, `⌥`, `⌃` 중 하나는 포함해야 하고, 다른 앱이 이미 쓰는 조합은 쓸 수 없습니다.

## 삭제

1. 메뉴에서 CursorMoving을 종료합니다.
2. `응용 프로그램`에서 `CursorMoving.app`을 삭제합니다.
3. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 CursorMoving을 지웁니다. 로그인 자동 실행을 켰다면 **일반 → 로그인 항목**에서도 지웁니다.
4. 설정값까지 지우려면: `defaults delete com.imbotaem.cursormoving`

## 소스에서 빌드

Xcode 15 이상(Swift 5.9)이 필요합니다.

```bash
git clone https://github.com/importamt/cursor-moving.git
cd cursor-moving
swift test                         # 단위 테스트
./scripts/build-app.sh             # build/CursorMoving.app 생성
./scripts/build-app.sh --install   # /Applications 에 복사
open build/CursorMoving.app
```

`build-app.sh`는 키체인에 `Developer ID Application` 또는 `Apple Development` 인증서가 있으면 그걸로 서명하고 (`SIGN_IDENTITY`로 지정 가능), 없으면 ad-hoc으로 서명합니다.
인증서로 서명하면 다시 빌드해도 손쉬운 사용 권한이 유지됩니다. ad-hoc으로 서명하면 빌드할 때마다 손쉬운 사용 목록에서 CursorMoving을 지웠다가 다시 허용해야 합니다.

### 배포 (관리자용)

```bash
# 1회: 공증용 로그인 정보를 키체인에 저장
xcrun notarytool store-credentials cursormoving-notary --apple-id <Apple ID> --team-id <Team ID>

./scripts/release.sh   # 테스트 → 빌드 → 공증 → staple → build/CursorMoving-<버전>.zip
gh release create v<버전> build/CursorMoving-<버전>.zip --generate-notes
```

버전은 `Resources/Info.plist`의 `CFBundleShortVersionString`에서 가져옵니다.

### 구조

- `Sources/CursorMovingCore`: 순수 로직 (도형 경로, 유휴 판정, 단축키 조합, 문구)과 단위 테스트
- `Sources/CursorMoving`: AppKit 메뉴바 앱 (CGEvent 주입, Carbon 단축키, SwiftUI 환경설정, SMAppService 로그인 항목)

## 라이선스

[MIT](LICENSE)
