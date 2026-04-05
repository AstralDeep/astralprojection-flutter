<!--
Sync Impact Report
==================
- Version change: 0.0.0 → 1.1.0 (initial ratification + amendment)
- Added principles:
  I.   SDUI Thin Client
  II.  Cross-Platform Parity
  III. WebSocket-First Transport
  IV.  ROTE-Aware Rendering
  V.   Local Shell Ownership
  VI.  Test-First (NON-NEGOTIABLE)
  VII. Simplicity & YAGNI
- Added sections:
  - Technology Constraints
  - Development Workflow
  - React Archive Reference
  - Governance
- Modified principles:
  - V. Local Shell Ownership — added UI Drawer and "Add to UI" button
- Removed sections: none (first version)
- Templates requiring updates:
  - .specify/templates/plan-template.md — ⚠ pending (plan template is
    generic; constitution gates will be applied at plan-creation time)
  - .specify/templates/spec-template.md — ⚠ pending (same; no structural
    change needed, constitution gates checked at spec-creation time)
  - .specify/templates/tasks-template.md — ⚠ pending (same)
- Follow-up TODOs: none
-->

# AstralProjection Flutter — Constitution

## Core Principles

### I. SDUI Thin Client

The Flutter application is a **rendering surface** for Server-Driven UI
payloads produced by the AstralBody backend. The main dashboard content
area MUST NOT contain hard-coded screens or business logic beyond what is
required to interpret and render the backend's component JSON.

- Every backend component type defined in `backend/shared/primitives.py`
  MUST have a corresponding Flutter widget in
  `lib/components/primitives/`.
- The `DynamicRenderer` (`lib/components/dynamic_renderer.dart`) is the
  single entry point for mapping backend component dicts to widgets.
- New primitive widgets MUST only be added when the backend introduces a
  new component type. Do not invent client-only primitives for the main
  content area.

### II. Cross-Platform Parity

The application MUST build and run on all of the following targets with
feature-equivalent behavior:

| Platform        | Form Factor |
|-----------------|-------------|
| iOS             | Mobile      |
| Android         | Mobile      |
| iPadOS          | Tablet      |
| Android Tablet  | Tablet      |
| Windows         | Desktop     |
| macOS           | Desktop     |

- Every Flutter package added to `pubspec.yaml` MUST support **all six
  targets** listed above. If a package lacks support for any target, it
  MUST NOT be used unless wrapped behind a platform-conditional import
  with a documented fallback.
- Platform-specific code (e.g., `lib/platform/`) is permitted only for
  device-specific affordances (e.g., TV focus management, watch layout)
  that do not exist on other platforms.
- UI layouts MUST be responsive. Use `LayoutBuilder`,
  `MediaQuery`, and breakpoints — never hard-coded pixel dimensions for
  layout containers.

### III. WebSocket-First Transport

The primary communication channel between the Flutter client and the
AstralBody backend MUST be a persistent WebSocket connection
(`ws://` / `wss://`).

- The `WebSocketProvider` (`lib/state/web_socket_provider.dart`) owns the
  connection lifecycle: connect, reconnect, send, receive.
- All `ui_render`, `ui_update`, `ui_append`, `ui_event`, `ui_action`,
  `chat_status`, `system_config`, `rote_config`, and `history_list`
  messages MUST travel over WebSocket.
- Alternative transports (HTTP REST, gRPC, etc.) are allowed **only**
  when there is a clear performance justification — e.g., binary file
  uploads/downloads where streaming over WS would be inefficient. Each
  such exception MUST be documented in a code comment at the call site
  with the rationale.

### IV. ROTE-Aware Rendering

The backend's ROTE middleware adapts UI payloads per device. The Flutter
client MUST cooperate by:

1. Reporting accurate `DeviceCapabilities` in the `register_ui` message
   at connection time (screen size, pixel ratio, touch support,
   microphone, camera, file system, connection type).
2. The `DeviceProfileProvider`
   (`lib/state/device_profile_provider.dart`) MUST detect capabilities at
   runtime — never hard-code them.
3. The client MUST faithfully render whatever adapted payload it receives.
   Client-side re-adaptation or overriding of ROTE decisions is
   prohibited; the backend is the single source of truth for layout
   adaptation.

### V. Local Shell Ownership

The following UI surfaces are **client-owned** and not driven by backend
SDUI payloads:

- **Login screen** — authentication flow, token acquisition
- **Dashboard sidebar** — chat history, workspace/project navigation
- **Dashboard navbar** — top-bar controls, user menu
- **Chat input bar** — text entry, voice input, file attachment
- **Agent manager** — agent list, permissions, status
- **UI Drawer** (`lib/components/workspace/saved_components_drawer.dart`)
  — a static, client-owned panel where users can save, view, delete,
  combine, and condense SDUI components for later reference
- **"Add to UI" button** — each SDUI component rendered in the main
  content area MUST display an "Add to UI" affordance that saves that
  component to the UI Drawer. This button is client-side chrome, not
  part of the backend payload.

These surfaces MAY contain hard-coded Flutter widgets and local state.
They MUST still communicate with the backend via the WebSocket protocol
for data (e.g., fetching chat history, sending queries, managing agents,
saving/retrieving UI Drawer contents) but their UI layout is determined
client-side.

### VI. Test-First (NON-NEGOTIABLE)

- Widget tests MUST be written before implementing new primitive widgets.
- Integration tests MUST cover the WebSocket connection lifecycle
  (connect → register_ui → receive ui_render → send ui_event).
- Red-Green-Refactor: tests written → tests fail → implement → tests
  pass → refactor.
- The `test/` directory mirrors `lib/` structure.

### VII. Simplicity & YAGNI

- Do not introduce abstractions, services, or packages for hypothetical
  future requirements.
- Prefer `Provider` for state management. Do not migrate to Bloc, Riverpod,
  or other state libraries without an explicit constitution amendment.
- Start with the simplest implementation that satisfies the current spec.
  Refactor only when complexity is demonstrated, not anticipated.

## Technology Constraints

- **Language**: Dart (SDK ^3.9.0) with Flutter
- **State management**: `provider` (^6.x)
- **WebSocket**: `web_socket_channel` (^3.x)
- **Charts**: `fl_chart` (^1.x) — cross-platform, no native dependency
- **Secure storage**: `flutter_secure_storage` (^10.x) — for auth tokens
- **HTTP** (supplementary only): `http` (^1.x)
- **Markdown rendering**: `flutter_markdown_plus` (^1.x)
- **Audio recording**: `record` (^6.x) — for voice input
- **File picking**: `file_picker` (^11.x)
- **URL launching**: `url_launcher` (^6.x)
- **WebView**: `flutter_inappwebview` (^6.x)
- **Connectivity**: `connectivity_plus` (^7.x)
- All packages MUST be compatible with iOS, Android, Windows, and macOS.
  Any platform gap MUST be documented and wrapped with a conditional
  fallback before merging.

## Development Workflow

- **Branch naming**: `###-feature-name` (numeric prefix matching spec)
- **Commits**: atomic, one logical change per commit
- **Code review**: all PRs MUST verify compliance with this constitution
  before merge
- **Responsive testing**: every PR that touches UI MUST be verified on at
  least one mobile and one desktop target before merge
- **No dead code**: unused widgets, imports, or packages MUST be removed
  in the same PR that makes them obsolete

## React Archive Reference

The original React/TypeScript frontend lives at
`AstralBody/frontend-archive-react/` and serves as a **read-only
reference** for understanding interaction flows, WebSocket message
sequences, and UI component behavior.

**Rules for using the archive:**

- The archive MAY be consulted to understand:
  - WebSocket message flows (connect → register → render cycle)
  - How specific backend component types were rendered (e.g., chart
    interactivity, table pagination, collapsible state)
  - UI event dispatch patterns (`ui_event` action names and payloads)
  - Dashboard layout structure (sidebar, navbar, main content split)
- The archive MUST NOT be directly ported or copied. The Flutter
  frontend is a new implementation with its own idioms (Provider state,
  Flutter widget tree, Dart conventions). Line-for-line translation
  from React/TS produces non-idiomatic, fragile Flutter code.
- When referencing the archive during implementation, document the
  specific file consulted in a code comment (e.g.,
  `// Flow reference: frontend-archive-react/src/hooks/useWebSocket.ts`)
  so reviewers can verify the intent was understood, not blindly copied.

**Key archive files for reference:**

| Purpose                  | Archive Path                                      |
|--------------------------|---------------------------------------------------|
| WebSocket hook           | `src/hooks/useWebSocket.ts`                       |
| Component renderer       | `src/components/DynamicRenderer.tsx`               |
| Component catalog        | `src/catalog.ts`                                  |
| Dashboard layout         | `src/components/` (layout files)                  |

## Governance

This constitution is the supreme authority for architectural and process
decisions in the AstralProjection Flutter project. It supersedes all
other practices, conventions, or ad-hoc agreements.

- **Amendments** require: (1) a written proposal documenting the change
  and rationale, (2) explicit approval, (3) a migration plan if
  existing code is affected.
- **Versioning** follows semantic versioning:
  - MAJOR: backward-incompatible governance or principle removal/
    redefinition
  - MINOR: new principle or materially expanded guidance
  - PATCH: clarification, wording, or typo fix
- **Compliance review**: every PR/review MUST verify that changes do not
  violate any principle. Violations MUST be justified in a Complexity
  Tracking table (see plan template) or rejected.

**Version**: 1.1.0 | **Ratified**: 2026-04-05 | **Last Amended**: 2026-04-05
