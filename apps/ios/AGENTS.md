# AGENTS.md — Kiwi iOS

## Commands

**Build (Debug):**
```sh
xcodebuild \
  -project apps/ios/Kiwi.xcodeproj \
  -scheme Kiwi \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  build
```

**Unit + UI tests:**
```sh
xcodebuild \
  -project apps/ios/Kiwi.xcodeproj \
  -scheme Kiwi \
  -destination "generic/platform=iOS Simulator" \
  test
```

## Notes
- Scheme: Kiwi
- Snapshot tests: add expectations if snapshot testing is introduced later.
