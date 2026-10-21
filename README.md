# CursorMoving

macOS 메뉴바 앱 — 주기적 커서 이동 + 마우스 클릭 녹화/재생

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
| ⌃⌥⌘R | 클릭 녹화 시작/중지 |
| ⌃⌥⌘P | 최근 녹화 재생/중지 |

## 메뉴바 아이콘

- 회색 화살표: 꺼짐 / 초록 화살표(모션라인): 커서 이동 중 / 빨간 원: 녹화 중 / 파란 재생: 재생 중

## 권한

- **손쉬운 사용**: 커서 이동, 클릭 재생
- **입력 모니터링**: 클릭 녹화

ad-hoc 서명이라 재빌드하면 권한 목록에서 CursorMoving 을 제거(−) 후 다시 허용해야 할 수 있다.

## 구조

- `Sources/CursorMovingCore` — 순수 로직 (이동 좌표 계산, 녹화 빌더, 저장소) + 테스트
- `Sources/CursorMoving` — AppKit 메뉴바 앱 (CGEvent 주입, EventTap 녹화, Carbon 단축키)
- 녹화 파일: `~/Library/Application Support/CursorMoving/Recordings/*.json`
