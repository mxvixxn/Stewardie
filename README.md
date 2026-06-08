<div align="center">

# 🚀 Stewardie

**필요 없는 메뉴바 아이콘을 진짜로 숨기고, 필요할 때 한 번에 꺼내세요.**
*Truly hide the menu bar icons you don't need — and bring them all back with one click.*

[![Download](https://img.shields.io/badge/⬇_Download-latest-blue)](https://github.com/mxvixxn/Stewardie/releases/latest)
![Platform](https://img.shields.io/badge/macOS-13%2B-black)
![Public API only](https://img.shields.io/badge/API-public%20only-green)

</div>

---

## 무엇인가요? · What is it?

**KR** — Stewardie는 가벼운 macOS 메뉴바 정리 도구예요. 자주 안 쓰는 아이콘을
구분선 왼쪽으로 옮겨두면, 클릭 한 번에 화면 밖으로 **완전히 숨겼다가**
다시 꺼낼 수 있어요. 좁은 메뉴바를 위한 작은 "보관함"이에요.

**EN** — Stewardie is a lightweight macOS menu bar manager. Drag the icons you
rarely use to the left of its divider, and a single click slides them
**completely off-screen** — then brings them back. A small "archive" for a
crowded menu bar.

---

## 기능 · Features

| | KR | EN |
|---|---|---|
| 🫥 | **진짜 숨김** — 아이콘이 사라지고 공간도 닫혀요 | **True hiding** — the icon disappears and the gap closes |
| 🖱️ | **클릭 한 번 토글** — 구분선 왼쪽 전체를 숨김/표시 | **One-click toggle** — hide/show everything left of the divider |
| 🗄️ | **보관함** — 지금 숨겨진 항목 목록 보기 | **Archive** — see what's currently hidden |
| ⚙️ | **설정** — 로그인 시 자동 실행, 권한 관리 | **Settings** — launch at login, permission management |
| 🔄 | **업데이트 알림** — 새 버전이 나오면 알려줘요 | **Update check** — notifies you when a new version is out |

> **공개 API만 사용해요.** 다른 앱 아이콘을 옮기는 데 비공개 API를 쓰지 않아서,
> 모든 메뉴바 앱에서 안정적으로 동작합니다.
> *Uses public AppKit API only — works reliably with every menu bar app.*

---

## 설치 · Install

**KR**
1. [최신 릴리스](https://github.com/mxvixxn/Stewardie/releases/latest)에서 `Stewardie.app.zip` 다운로드
2. 압축을 풀고 `Stewardie.app`을 **응용 프로그램** 폴더로 드래그
3. Spotlight(⌘-Space)에서 "Stewardie" 검색해 실행
4. 첫 실행 시 "확인되지 않은 개발자" 경고가 뜨면, 앱을 **우클릭 → 열기**

**EN**
1. Download `Stewardie.app.zip` from the [latest release](https://github.com/mxvixxn/Stewardie/releases/latest)
2. Unzip and drag `Stewardie.app` into your **Applications** folder
3. Launch it via Spotlight (⌘-Space → "Stewardie")
4. On first launch, if macOS warns about an unidentified developer, **right-click → Open**

---

## 사용법 · How to use

**KR**
1. 메뉴바에서 Stewardie 아이콘 왼쪽의 **구분선(｜)**을 찾으세요
2. **⌘-드래그**로 숨기고 싶은 아이콘을 구분선 **왼쪽**으로 옮기세요
3. Stewardie 아이콘을 **클릭**하면 구분선 왼쪽 항목이 한 번에 숨겨지거나 나타나요
4. **우클릭**(또는 ⌥/⌃-클릭)으로 보관함·설정 메뉴를 열 수 있어요

**EN**
1. Find the **divider (｜)** to the left of the Stewardie icon
2. **⌘-drag** the icons you want to hide to the **left** of the divider
3. **Click** the Stewardie icon to hide/show everything left of the divider
4. **Right-click** (or ⌥/⌃-click) to open the Archive and Settings

---

## 권한 · Permissions

**KR** — 숨기기/꺼내기 핵심 기능은 권한이 필요 없어요. 보관함의 "현재 숨겨진 항목"
목록만 **손쉬운 사용** 권한을 사용해요(읽기 전용).

**EN** — The core hide/show feature needs no permission. Only the Archive's
"currently hidden" list uses the **Accessibility** permission (read-only).

---

## 개발자용 · For developers

```bash
git clone https://github.com/mxvixxn/Stewardie.git
cd Stewardie
./script/build_and_run.sh        # 빌드 + .app 번들 + 실행 / build, bundle, launch
```

요구사항 · Requirements: macOS 13+, Swift 6 / Xcode 16+

---

## 동작 원리 · How it works

**KR** — Stewardie는 메뉴바에 얇은 **구분선** 상태 아이템을 둬요. 이 아이템의
길이를 크게 늘리면 왼쪽 아이콘들이 화면 밖으로 밀려나 사라지고, 줄이면 돌아와요.
순수 `NSStatusItem.length` (공개 API) 기법이에요.

**EN** — Stewardie places a thin **divider** status item in the menu bar.
Expanding its length pushes the icons on its left off-screen; shrinking it
brings them back. Pure `NSStatusItem.length` — public API.

---

<div align="center">
<sub>Made by <a href="https://github.com/mxvixxn">mxvixxn</a> · 🤖 built with Claude Code</sub>
</div>
