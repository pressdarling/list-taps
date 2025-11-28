# list-taps

A Swift library that enumerates macOS event taps using the Core Graphics API.

## Build Commands

```bash
# Build the package
swift build

# Run tests
swift test
```

## Project Structure

- `Sources/list-taps/list_taps.swift` - Main library code that queries event taps via `CGGetEventTapList`
- `Tests/list-tapsTests/` - Test suite using Swift Testing framework
- `Package.swift` - Swift Package Manager configuration (requires Swift 6.2+)

## Technical Notes

- Uses `CGGetEventTapList` from ApplicationServices to enumerate system event taps
- Uses `proc_pidpath` from Darwin to resolve process paths from PIDs
- Outputs JSON array with tap details: tapID, enabled status, source/destination PIDs and paths
- Requires macOS (uses platform-specific APIs)
