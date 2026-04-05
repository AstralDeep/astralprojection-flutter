# Cross-Device Manual QA Matrix

**Feature**: Flutter Migration QA & Feature Parity (002)
**Date**: 2026-04-03

## Device Matrix

| Test Case | iOS Phone | Android Phone | iOS Tablet | Android Tablet | Apple TV | Apple Watch |
|-----------|-----------|---------------|------------|----------------|----------|-------------|
| **Login** | | | | | | |
| Username/password form visible | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| SSO button visible | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| Login < 5s | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| SSO login < 10s | [ ] | [ ] | [ ] | [ ] | N/A | N/A |
| Glass-morphism card renders | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| Error messages display inline | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| **Dashboard** | | | | | | |
| SDUI tree renders | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| SDUI updates < 1s | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Chat input works | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| Sidebar visible | [ ] | [ ] | [ ] | [ ] | N/A | N/A |
| **Voice** | | | | | | |
| Mic button visible | [ ] | [ ] | [ ] | [ ] | Hidden | Hidden |
| Speaker toggle visible | [ ] | [ ] | [ ] | [ ] | Hidden | Hidden |
| Voice input streams | [ ] | [ ] | [ ] | [ ] | N/A | N/A |
| TTS playback works | [ ] | [ ] | [ ] | [ ] | N/A | N/A |
| **File Upload** | | | | | | |
| Attachment button works | [ ] | [ ] | [ ] | [ ] | Hidden | Hidden |
| File picker opens | [ ] | [ ] | [ ] | [ ] | N/A | N/A |
| **Saved Components** | | | | | | |
| Grid displays | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| Drag-and-drop combine | [ ] | [ ] | [ ] | [ ] | N/A | N/A |
| Condense All button | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| Delete component | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| **Agent Permissions** | | | | | | |
| 4 scope cards render | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| Tool toggles work | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| Confirmation dialog | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| **Visual Parity** | | | | | | |
| Colors match React | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| Glass-morphism effects | [ ] | [ ] | [ ] | [ ] | [ ] | N/A |
| **TV-Specific** | | | | | | |
| D-pad navigation | N/A | N/A | N/A | N/A | [ ] | N/A |
| Focus indicators (amber) | N/A | N/A | N/A | N/A | [ ] | N/A |
| 1.5x text scale | N/A | N/A | N/A | N/A | [ ] | N/A |
| 5 presses to any dest | N/A | N/A | N/A | N/A | [ ] | N/A |
| **Watch-Specific** | | | | | | |
| Dashboard < 3s load | N/A | N/A | N/A | N/A | N/A | [ ] |
| Chart → metric degrade | N/A | N/A | N/A | N/A | N/A | [ ] |
| Table → list degrade | N/A | N/A | N/A | N/A | N/A | [ ] |
| Unsupported skipped | N/A | N/A | N/A | N/A | N/A | [ ] |
| **Connectivity** | | | | | | |
| Offline indicator shows | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Reconnect backoff works | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Cached tree on restart | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Rotation preserves state | [ ] | [ ] | [ ] | [ ] | N/A | N/A |

## Test Devices

| Device | Method | Viewport |
|--------|--------|----------|
| iPhone 15 | iOS Simulator | 393x852 |
| Pixel 8 | Android Emulator | 412x915 |
| iPad Pro 12.9" | iOS Simulator | 1024x1366 |
| Galaxy Tab S9 | Android Emulator | 800x1280 |
| Apple TV 4K | tvOS Simulator | 1920x1080 |
| Apple Watch S9 | watchOS Simulator | 205x251 |
