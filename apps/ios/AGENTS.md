# AGENTS.md — Kiwi iOS App

## Build Commands

### Build (Debug)

```sh
xcodebuild \
  -project apps/ios/Kiwi.xcodeproj \
  -scheme Kiwi \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  build
```

### Run Unit + UI Tests

```sh
xcodebuild \
  -project apps/ios/Kiwi.xcodeproj \
  -scheme Kiwi \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  test
```

## Project Details

- **Xcode Scheme**: `Kiwi`
- **Deployment Target**: iOS 26.0
- **Swift Version**: 6.0
- **Strict Concurrency**: Enabled (`complete`)
- **Dependencies**: None (Apple frameworks only)
- **Signing**: Automatic, placeholder team

## Architecture

Feature-first modular MVVM with clean architecture boundaries:

- `App/` — Entry point and top-level state
- `Features/` — Scan, Results, RecipeDetail, Account
- `Domain/` — Models and use cases (pure logic)
- `Data/` — Networking, auth, image processing, rate limiting
- `Shared/` — Reusable UI components and theme

## Testing

- **Unit Tests** (`KiwiTests/`):
  - Domain: model decoding, use case logic
  - Data: API client, metadata stripper, rate limiter
  - ViewModels: state management, error handling
- **UI Tests** (`KiwiUITests/`):
  - Scan flow: UI element presence
  - Account flow: sign-in, deletion confirmation

## Snapshot Tests

Not yet implemented. When added:
- Place in `KiwiTests/Snapshots/`
- Cover key views in both light and dark mode
- Record baselines before committing

## Accessibility Requirements

- Dynamic Type on all text (semantic fonts only)
- VoiceOver labels on all interactive elements
- 44x44pt minimum touch targets
- Logical navigation order
