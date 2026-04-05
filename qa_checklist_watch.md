# QA Checklist -- Apple Watch (T058)

Manual QA checklist for verifying Apple Watch rendering and interaction.

## Component Rendering (Supported Types)

- [ ] `text` -- renders readable text content
- [ ] `metric` -- renders title, value, and optional icon/progress bar
- [ ] `alert` -- renders alert message with appropriate variant styling
- [ ] `card` -- renders card container with content
- [ ] `button` -- renders tappable button with label
- [ ] `list` -- renders scrollable list of items
- [ ] `progress` -- renders progress indicator with label
- [ ] `divider` -- renders visual separator
- [ ] `container` -- renders container with nested children

## Chart Degradation

- [ ] `bar_chart` degrades to metric widget (title + first data value)
- [ ] `line_chart` degrades to metric widget (title + first data value)
- [ ] `pie_chart` degrades to metric widget (title + first data value)
- [ ] `plotly_chart` degrades to metric widget (title + first data value)
- [ ] Degraded metric shows chart icon indicator
- [ ] Charts with no data show "--" fallback value

## Table Degradation

- [ ] `table` degrades to list widget showing first column values
- [ ] Table with empty rows degrades to empty list (no crash)
- [ ] Column headers are not shown in degraded list view

## Glanceable Layout

- [ ] All content fits within the watch screen without horizontal scrolling
- [ ] Text is legible on small screen (38mm and 42mm watch faces)
- [ ] Dashboard components are vertically scrollable
- [ ] No content is clipped or overlapping

## Performance

- [ ] Dashboard loads within 3 seconds target
- [ ] Scrolling through components is smooth (no dropped frames)
- [ ] No visible jank when switching between screens

## Button Interactivity

- [ ] Tapping a button dispatches the correct event action
- [ ] Button tap triggers server response and UI updates accordingly
- [ ] Button shows visual feedback on tap (pressed state)
- [ ] Multiple rapid taps do not cause duplicate events or crashes

## Unsupported Components

- [ ] Unsupported types (html_view, code_editor, file_upload, etc.) are silently skipped
- [ ] No error messages or blank spaces appear for skipped components
- [ ] Dashboard with all unsupported types shows empty/fallback state gracefully
