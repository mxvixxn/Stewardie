 # Stewardie — Project Brief for Codex

## 프로젝트 개요

**Stewardie**는 macOS 메뉴바 아이콘을 자유롭게 관리할 수 있는 메뉴바 앱이다.
이름은 "Stewardess(승무원)"에서 영감을 받았으며, 조용히 뒤에서 사용자의 메뉴바를 척척 정리해주는 컨셉이다.
Bartender(유료 $16)의 오픈 대안으로, 사용자가 원하는 대로 커스텀할 수 있는 자유로운 도구를 목표로 한다.

---

## 기술 스택

| 항목 | 내용 |
|---|---|
| 플랫폼 | macOS |
| 언어 | Swift |
| UI 프레임워크 | AppKit (+ SwiftUI 부분 혼용 가능) |
| 핵심 API | `NSStatusBar`, `NSStatusItem`, Private API (`CGSPrivate` 등) |
| 배포 방식 | 자체 배포 (App Store 외) — Private API 사용으로 App Store 불가 |
| 최소 macOS 버전 | macOS 13 Ventura 이상 권장 |

---

## 핵심 기능 명세

### 1. 아이콘 숨기기 / 꺼내기
- 사용자가 지정한 메뉴바 아이콘을 평소에 숨김 처리
- Stewardie 아이콘 클릭 또는 단축키로 숨긴 아이콘 펼치기
- 숨김 상태는 앱 재시작 후에도 유지 (UserDefaults 또는 plist 저장)

### 2. 위치 재배치
- 메뉴바 아이콘 순서를 드래그 앤 드롭으로 자유롭게 변경
- 시스템 아이콘(와이파이, 배터리 등) 포함 재배치 가능

### 3. 완전 제거
- 특정 아이콘을 메뉴바에서 아예 보이지 않도록 제거
- 복원 기능 포함 (실수로 지워도 되돌릴 수 있게)

### 4. 프로필 (추후 구현)
- 상황별 레이아웃 저장 (예: 집중모드 / 기본모드)
- 단축키로 프로필 전환

---

## 개발 단계 (로드맵)

```
1단계 — 기본 구조
  - Xcode macOS 프로젝트 생성 (App, Menu Bar Extra 타입)
  - NSStatusBar로 Stewardie 아이콘 메뉴바에 올리기
  - 클릭 시 드롭다운 메뉴 표시

2단계 — 아이콘 숨기기 / 꺼내기
  - Private API로 다른 앱 메뉴바 아이콘 목록 읽기
  - 숨김 지정 UI 구현
  - 클릭/단축키로 펼치기

3단계 — 위치 재배치
  - 드래그 앤 드롭 UI
  - 재배치 상태 저장

4단계 — 완전 제거 + 복원
  - 제거 기능 + 복원 목록 관리

5단계 — 프로필 + 마무리
  - 프로필 저장/전환
  - 온보딩 화면
  - 배포 준비 (코드 서명, Notarization)
```

---

## 주의사항

- **Private API 사용**: `CGSPrivate`, `CGSConnection` 등 비공개 헤더를 사용함. App Store 배포 불가, 자체 배포만 가능.
- **권한**: Accessibility 권한 요청 필요 (`Accessibility` entitlement).
- **Apple Silicon 대응**: M 시리즈 맥 기준으로 개발 (개발자 본인 기기: MacBook Pro 14-inch M5 Pro).
- **코드 서명**: 배포 시 Developer ID로 서명 + Notarization 필요.

---

## 개발 환경

- 기기: MacBook Pro 14-inch M5 Pro (24GB RAM, 1TB)
- Xcode 최신 버전
- 개발자 Swift 학습 중 (기초~중급 수준)
