# QA Checklist -- Visual Parity (T044)

Manual QA checklist for verifying visual parity between React and Flutter clients.

## Side-by-Side Screenshot Comparisons

Capture and compare the following screens in both React (archived) and Flutter clients at the same viewport size:

- [ ] **Login screen** -- layout, spacing, field placement, button positioning
- [ ] **Dashboard** -- component grid, card layout, metric widgets, charts
- [ ] **Chat interface** -- message bubbles, input area, streaming text display
- [ ] **Agent permissions** -- permission sheet layout, toggle/checkbox alignment
- [ ] **Saved components** -- component list, card display, action buttons

## Glass-Morphism Effects

- [ ] BackdropFilter blur applied to login card (sigmaX: 12, sigmaY: 12)
- [ ] Semi-transparent surface on glass cards (surface color with ~0.6 alpha)
- [ ] Subtle white border on glass cards (white with ~0.1 alpha)
- [ ] Blur effect renders without artifacts on all target platforms
- [ ] Glass effect is visually consistent with React ClipPath/backdrop-filter

## Color Scheme

- [ ] Background color matches: `#0F1221` (0xFF0F1221)
- [ ] Primary color matches: `#6366F1` (0xFF6366F1)
- [ ] Secondary color matches: `#8B5CF6` (0xFF8B5CF6)
- [ ] Surface color matches: `#1A1E2E` (0xFF1A1E2E)
- [ ] Text color matches: `#F3F4F6` (0xFFF3F4F6)
- [ ] SSO button accent matches: `#06B6D4` (0xFF06B6D4)
- [ ] Error states use red accent consistently
- [ ] Gradient backgrounds (top-left to bottom-right) match React implementation

## Typography

- [ ] Headlines use Inter or Lato font family (via google_fonts)
- [ ] Body text uses Roboto font family
- [ ] Font weights match React: headlines bold (w700), body regular (w400)
- [ ] Font sizes are proportionally equivalent at same viewport size
- [ ] Line height / letter spacing matches React implementation
- [ ] Text does not overflow or clip in any component

## Layout and Spacing

- [ ] Login card width matches (~380px on desktop/tablet)
- [ ] Login card padding matches (32px internal padding)
- [ ] Field spacing matches (16px between fields, 24px before buttons)
- [ ] OR divider spacing matches (20px vertical padding)
- [ ] Dashboard card margins and padding match React grid layout
- [ ] Navigation bar height and icon sizes match

## Interactive Elements

- [ ] Elevated button style matches (primary background, white text, rounded corners)
- [ ] Outlined button style matches (transparent background, colored border)
- [ ] Input field border colors match (white 0.2 alpha default, primary on focus)
- [ ] Input field prefix icons match (person_outline, lock_outline)
- [ ] Loading spinner matches (CircularProgressIndicator, white, 2px stroke)
- [ ] Error container styling matches (red 0.15 alpha background, red accent text)

## Responsive Behavior

- [ ] Mobile layout matches React mobile breakpoint
- [ ] Tablet layout matches React tablet breakpoint
- [ ] Desktop layout matches React desktop breakpoint
- [ ] Transition between breakpoints is smooth and consistent
