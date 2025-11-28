# `list-taps` Project Guidance

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

```bash
# Build
swift build

# Run tests
swift test

# Build release
swift build -c release
```

## What This Tool Does

`list-taps` is a macOS security auditing utility that enumerates all active [event taps](https://developer.apple.com/documentation/coregraphics/quartz_event_services) on the system. Event taps allow processes to intercept keyboard, mouse, and other input events - used legitimately by accessibility software but also by keyloggers and other monitoring tools.

Requires Accessibility permissions to see taps from other processes.

The tool outputs JSON with:
- The tapping process (PID and path)
- The target process (or "All processes" for global taps)
- Whether the tap is currently enabled

## Architecture

Single-file implementation in `Sources/list-taps/list_taps.swift`:
1. Calls `CGGetEventTapList` twice - first to get count, then to populate buffer
2. Uses `proc_pidpath` to resolve PIDs to executable paths
3. Outputs JSON array to stdout
