# Flutter Home Screen Search UI/UX Synchronization

Synchronize the Flutter Home screen's origin-destination search UI with the recently updated React version. This involves applying a modern "Glassmorphism" aesthetic, improved visual hierarchy, and polished interactions.

## User Review Required

> [!IMPORTANT]
> The search functionality (API calls, state management) will remain unchanged. This update focuses strictly on the visual presentation (Widgets, Decoration, Layout) of the search header on the Home screen.

## Proposed Changes

### [Flutter Home Screen]

#### [MODIFY] [home_screen.dart](file:///C:/Users/rbal5/AndroidStudioProjects/busing/lib/screens/home_screen.dart)
- **Search Header**:
    - Apply `BackdropFilter` for the glass effect.
    - Use semi-transparent backgrounds and subtle borders.
    - Implement glowing indicators (dots) for origin and destination.
    - Redesign the layout to be more "floating" and integrated with the map.
    - Update the "Swap" and "Clear" buttons to match the React version's style.
- **Floating Action Buttons**:
    - Subtle refinement to match the overall glassy theme.

## Verification Plan

### Manual Verification
- Run the Flutter app and verify the Home screen's search header appearance.
- Test interactions:
    - Tap on origin/destination to open search.
    - Verify "Swap" functionality visually.
    - Verify "Clear" button appearance and behavior.
- Check the "near destination" banner for visual consistency.
