# CursorMoving

macOS 메뉴바 앱 — 유휴 시 커서로 도형 그리기

## 커서 이동

키보드·마우스 입력이 **유휴 감지 시간**(5초/10초/15초/30초/1분/5분, 기본 30초) 동안 없으면
현재 위치에서 약 2초에 걸쳐 **모양**(지그재그/동그라미/네모/별)을 그리고 제자리로 돌아온다.
그리는 도중 마우스를 움직이거나 키를 누르면 즉시 멈춘다.

메뉴의 **언어**에서 시스템 설정 따름 / 한국어 / English 를 고를 수 있다.

## 빌드 & 실행

```bash
swift test                      # 단위 테스트
./scripts/build-app.sh          # build/CursorMoving.app 생성
./scripts/build-app.sh --install  # /Applications 에 설치
open build/CursorMoving.app
```

## 단축키

| 단축키 | 동작 |
|--------|------|
| ⌃⌥⌘M | 커서 이동 켜기/끄기 |

## 메뉴바 아이콘

- 회색 화살표: 꺼짐 / 초록 화살표(모션라인): 커서 이동 중

## 권한

- **손쉬운 사용**: 커서 이동

빌드 스크립트는 키체인의 `Developer ID Application` / `Apple Development` 인증서로 서명한다 (`SIGN_IDENTITY` 로 지정 가능).
인증서 서명은 팀 ID 기준이라 재빌드해도 권한이 유지된다. 인증서가 없으면 ad-hoc 서명으로 대체되며,
이때는 재빌드마다 권한 목록에서 CursorMoving 을 제거(−) 후 다시 허용해야 한다.

## 구조

- `Sources/CursorMovingCore` — 순수 로직 (도형 경로 계산, 유휴 판정, 한/영 문구) + 테스트
- `Sources/CursorMoving` — AppKit 메뉴바 앱 (CGEvent 주입, Carbon 단축키)
