# Stewardie — 채팅용 컨텍스트 브리핑

> 폴더에 접근할 수 없는 Claude 채팅(claude.ai)에게 이 앱을 한 번에 이해시키기 위한 요약본입니다.
> 최종 갱신: 2026-08-04

---

## ⚠️ 먼저 읽을 것 — 이 저장소의 오래된 문서

같은 폴더의 **`docs/PROJECT_BRIEF.md`와 `docs/TECHNICAL_NOTES.md`는 초기 기획 문서이고, 지금 코드와 다릅니다.**
그 문서들은 이렇게 적고 있지만 전부 **폐기된 방향**입니다:

| 옛 문서의 내용 | 실제 |
|---|---|
| `CGSPrivate`·`CGSConnection` 등 **비공개 API 사용** | 비공개 API를 쓰지 않음. **공개 AppKit + Accessibility API만** 사용 |
| "비공개 API 때문에 App Store 불가" | 그 전제가 사라짐 (현재는 GitHub Releases로 자체 배포) |
| 아이콘 **위치 재배치** 기능 | 구현 안 함 |
| 아이콘 **완전 제거** 기능 | 구현 안 함 |
| **프로필**(집중모드/기본모드) 전환 | 구현 안 함 |

**이 두 문서를 근거로 코드를 제안하지 마세요.** 판단 기준은 `README.md`와 이 문서입니다.

---

## 1. 한 문단 요약

**Stewardie**는 macOS **메뉴바 아이콘 정리 도구**입니다. 이름은 "Stewardess(승무원)"에서 왔고, 조용히 뒤에서 메뉴바를 정리해주는 컨셉이에요.
Bartender(유료 $16)의 무료 대안을 지향합니다.

동작 방식이 핵심인데, **비공개 API 없이** 이렇게 합니다:

1. Stewardie가 메뉴바에 **구분선(｜) 아이템**을 하나 올려둡니다.
2. 사용자가 **⌘-드래그**로 숨기고 싶은 아이콘을 구분선 **왼쪽**으로 옮깁니다. (이건 macOS 기본 기능)
3. Stewardie 아이콘을 클릭하면 구분선 아이템의 길이를 화면 밖까지 늘려서, 왼쪽 아이콘 전체를 **밀어내 가립니다.**
4. 다시 클릭하면 길이를 되돌려 복구.

즉 "아이콘을 조작"하는 게 아니라 **자기 아이템 폭으로 밀어내는** 방식이라, 모든 메뉴바 앱에서 안정적으로 동작하고 macOS 업데이트에도 잘 안 깨집니다. 이 설계가 이 프로젝트의 정체성이에요.

- 저장소: https://github.com/mxvixxn/Stewardie (브랜치 `main`)
- 로컬 경로: `~/Desktop/Stewardie`
- 배포: GitHub Releases에 `Stewardie.app.zip` (App Store 아님)

---

## 2. 기술 스택 / 제약

| 항목 | 값 |
|---|---|
| 플랫폼 | **macOS 13 Ventura 이상** |
| 언어 | Swift 6 (`swift-tools-version: 6.0`) |
| UI | **AppKit 주력** + SwiftUI 일부 화면(설정·보관함) |
| 빌드 시스템 | **SwiftPM (`Package.swift`)** — Xcode 프로젝트 파일 없음 |
| 실행 타깃 | `.executableTarget` 단일, `Sources/Stewardie` |
| 핵심 API | `NSStatusBar` / `NSStatusItem`, Accessibility(`AXUIElement`) |
| 권한 | 손쉬운 사용(Accessibility) 권한 필요 |
| 외부 의존성 | **없음** (SPM 패키지 0개) |
| 테스트 | 테스트 타깃 없음 |

> ⚠️ 다른 앱들(Moodie Sky, Fitie, Vocabie)은 iOS + SwiftUI인데 **Stewardie만 macOS + AppKit + SwiftPM**입니다. 헷갈리지 마세요.

---

## 3. 파일 구조

```
Package.swift                 SwiftPM 매니페스트 (macOS 13+, Swift 6)
Sources/Stewardie/
  main.swift                  진입점
  App/AppDelegate.swift       앱 수명주기, 메뉴바 아이템 설치
  Models/MenuBarItem.swift    메뉴바 아이템 모델
  Stores/MenuBarItemStore.swift  숨김 상태 보관·영속화
  Services/
    StewardieDivider.swift          ★구분선 아이템 — 숨김의 핵심 로직
    MenuBarIconService.swift        Accessibility로 메뉴바 아이콘 조회
    AccessibilityPermissionService.swift  권한 요청·상태 감시
    LaunchAtLoginService.swift      로그인 시 자동 실행
    UpdateService.swift             새 버전 확인 알림
  Views/
    StewardieSettingsView.swift  설정 (SwiftUI)
    StewardieArchiveView.swift   보관함 — 지금 숨겨진 항목 목록 (SwiftUI)
  Support/
    StewardieConstants.swift
    StewardieMenuBarIcon.swift
Design/                       앱 아이콘 소스 (로켓 모양)
dist/                         배포용 빌드 산출물
script/                       빌드·패키징 스크립트
docs/                         ⚠️ PROJECT_BRIEF·TECHNICAL_NOTES는 오래됨 (위 참고)
```

---

## 4. 구현된 기능

- 🫥 **진짜 숨김** — 아이콘이 사라지고 그 공간까지 닫힘
- 🖱️ **클릭 한 번 토글** — 구분선 왼쪽 전체를 숨김/표시
- 🗄️ **보관함** — 지금 숨겨진 항목 목록 확인
- ⚙️ **설정** — 로그인 시 자동 실행, 권한 관리
- 🔄 **업데이트 알림** — 새 버전 나오면 알려줌
- 우클릭(또는 ⌥/⌃-클릭)으로 보관함·설정 메뉴 열기

## 5. 아직 없는 것 (제안 시 참고)

- 단축키로 토글 (초기 기획엔 있었으나 미구현)
- 아이콘 순서 재배치 / 개별 영구 제거
- 프로필(상황별 레이아웃) 전환
- 코드 서명·공증 → 첫 실행 시 "확인되지 않은 개발자" 경고가 뜸 (README에 우클릭→열기 안내)

---

## 6. 채팅에게 부탁하고 싶은 것

1. **한국어 존댓말**로 답해 주세요.
2. **비공개 API를 쓰는 해법은 제안하지 마세요.** 공개 API만 쓰는 게 이 앱의 핵심 가치입니다.
3. 외부 라이브러리 없이 애플 순정 프레임워크로만 제안해 주세요.
4. `docs/PROJECT_BRIEF.md`·`docs/TECHNICAL_NOTES.md`를 보게 되면 **오래된 문서로 취급**하세요.
5. 파일 내용이 필요하면 추측하지 말고 붙여 달라고 요청해 주세요.
