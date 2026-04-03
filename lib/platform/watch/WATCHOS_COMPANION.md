# watchOS Companion App

## Overview

The watchOS companion is a **separate native SwiftUI target** built within the
iOS Xcode project. It is **not** a Flutter target. Flutter does not support
watchOS as a build target, so glanceable watch updates are delivered through a
native SwiftUI app that communicates with the AstralBody backend over
WebSockets.

This follows the research findings from **R5** (platform-specific companion
architecture): the watch surface is best served by a thin native client that
receives pre-filtered SDUI payloads.

## Architecture

```
AstralBody Backend
       |
       | WebSocket (wss://...)
       v
watchOS SwiftUI App
       |
       +-- WKExtensionDelegate  (lifecycle)
       +-- ContentView           (glanceable UI)
       +-- ComplicationController (watch face data)
```

## Required Setup Steps

### 1. Add the watchOS Target

1. Open the iOS Xcode project at `ios/Runner.xcworkspace`.
2. File > New > Target > watchOS > App (SwiftUI lifecycle).
3. Name the target `AstralWatch` (or your preferred name).
4. Set the bundle identifier to match your team prefix, e.g.
   `com.example.astral.watchkitapp`.
5. Ensure "Include Complication" is checked if you want watch face data.

### 2. Configure Signing and Capabilities

1. Select the `AstralWatch` target in Xcode.
2. Under Signing & Capabilities, set the correct team and provisioning profile.
3. Add the **Background Modes** capability with "Background App Refresh" and
   "Remote Notifications" enabled.

### 3. WebSocket Connection

The watch app connects to the same AstralBody backend WebSocket endpoint used
by the Flutter client.

- **Endpoint**: `wss://<ASTRAL_HOST>/ws`
- **Authentication**: Send the Keycloak OIDC access token in the initial
  WebSocket handshake via the `Authorization` header:
  ```
  Authorization: Bearer <access_token>
  ```
- **Registration message**: After connection, send a `register_ui` message with
  `device_type: "watch"` and `viewport_width: 200`:
  ```json
  {
    "type": "register_ui",
    "device_type": "watch",
    "viewport_width": 200,
    "viewport_height": 250,
    "capabilities": ["text", "metric", "alert", "card", "button", "list", "progress", "divider", "container"]
  }
  ```
- **Receiving updates**: The backend sends `ui_render` messages containing only
  watch-compatible components (pre-filtered server-side based on the declared
  capabilities). The SwiftUI views map these directly.
- **Sending events**: User interactions (button taps) send `ui_event` messages
  back over the same WebSocket:
  ```json
  {
    "type": "ui_event",
    "action": "button_click",
    "payload": { "id": "btn_refresh" }
  }
  ```

### 4. Token Sharing (iOS <-> watchOS)

Use **WatchConnectivity** (`WCSession`) to transfer the OIDC access token from
the iOS app to the watch app:

1. In the iOS Flutter app, use a platform channel to send the token via
   `WCSession.default.transferUserInfo(["token": accessToken])`.
2. In the watchOS app, implement `WCSessionDelegate` to receive the token in
   `session(_:didReceiveUserInfo:)`.
3. Store the token in the watchOS Keychain for reconnection.

### 5. Build and Run

1. Select the `AstralWatch` scheme in Xcode.
2. Choose a paired Apple Watch simulator or physical device.
3. Build and run (Cmd+R).

## Flutter-Side Watch Renderer

The Dart classes at `lib/platform/watch/watch_renderer.dart` and
`lib/platform/watch/watch_theme.dart` provide a Flutter-based watch renderer
and theme for testing and preview purposes. They demonstrate the component
filtering and degradation logic that the native watchOS app should replicate:

- **Supported types**: text, metric, alert, card, button, list, progress,
  divider, container
- **Chart degradation**: Charts become metric widgets (title + first value)
- **Table degradation**: Tables become list widgets (first column as items)
- **Unsupported types**: Silently skipped
