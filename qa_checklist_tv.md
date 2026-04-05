# QA Checklist -- Apple TV (T051)

Manual QA checklist for verifying TV navigation and display on Apple TV / tvOS.

## D-pad Navigation

- [ ] D-pad Up/Down/Left/Right moves focus predictably between all interactive elements
- [ ] Focus traversal order on login: Username -> Password -> Sign In -> SSO button
- [ ] Focus does not get trapped or lost on any screen
- [ ] D-pad navigation works on Login screen entirely without touch input
- [ ] D-pad navigation works on Dashboard screen
- [ ] Dashboard is reachable within 5 D-pad presses from home/login
- [ ] Back/Menu button navigates to previous screen or exits gracefully

## Focus Indicators

- [ ] Focus indicator is a 3px amber (#FFD600) border around the focused element
- [ ] Focus indicator is visible on all focusable elements (text fields, buttons, cards)
- [ ] Focus indicator contrast is sufficient against dark background (#0F1221)
- [ ] Focus indicator does not clip or overlap adjacent elements

## Text Readability (10ft Viewing Distance)

- [ ] 1.5x text scale factor is applied in TV mode
- [ ] Body text is legible at typical living-room viewing distance (~10ft)
- [ ] Headlines and titles are clearly distinguishable from body text
- [ ] No text is truncated or overflows its container on TV resolution

## Layout and Spacing

- [ ] 32px content padding is applied around screen edges
- [ ] Buttons have generous touch/focus targets (min 48x24px padding)
- [ ] Cards and list items have adequate spacing for D-pad selection
- [ ] UI elements are not crowded; layout feels spacious on large screen

## Platform-Specific Behavior

- [ ] Microphone/voice input controls are hidden (no mic button on TV)
- [ ] File picker is hidden (no file upload on TV)
- [ ] No touch-only gestures are required (swipe, pinch, drag)
- [ ] SELECT/ENTER on remote activates the focused element
- [ ] Long-press behavior (if any) works via remote long-press

## Visual Theme

- [ ] Dark theme matches design spec (background #0F1221, primary #6366F1)
- [ ] Glass-morphism card effects render correctly on tvOS
- [ ] Color contrast meets WCAG AA for large text
- [ ] AstralDeep branding is visible and correctly styled
