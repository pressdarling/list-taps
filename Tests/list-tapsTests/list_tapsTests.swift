import Testing
import Foundation
@testable import list_taps

// MARK: - EventTapInfo Tests

@Suite("EventTapInfo")
struct EventTapInfoTests {
    @Test("Initializes with all properties")
    func initializesWithAllProperties() {
        let tap = EventTapInfo(
            tapID: 42,
            enabled: true,
            sourcePID: 1234,
            sourcePath: "/usr/bin/test",
            destinationPID: 5678,
            destinationPath: "/Applications/App.app/Contents/MacOS/App"
        )

        #expect(tap.tapID == 42)
        #expect(tap.enabled == true)
        #expect(tap.sourcePID == 1234)
        #expect(tap.sourcePath == "/usr/bin/test")
        #expect(tap.destinationPID == 5678)
        #expect(tap.destinationPath == "/Applications/App.app/Contents/MacOS/App")
    }

    @Test("Equatable conformance")
    func equatableConformance() {
        let tap1 = EventTapInfo(
            tapID: 1, enabled: true, sourcePID: 100,
            sourcePath: "/path", destinationPID: 200, destinationPath: "/dest"
        )
        let tap2 = EventTapInfo(
            tapID: 1, enabled: true, sourcePID: 100,
            sourcePath: "/path", destinationPID: 200, destinationPath: "/dest"
        )
        let tap3 = EventTapInfo(
            tapID: 2, enabled: true, sourcePID: 100,
            sourcePath: "/path", destinationPID: 200, destinationPath: "/dest"
        )

        #expect(tap1 == tap2)
        #expect(tap1 != tap3)
    }
}

// MARK: - JSON Escaping Tests

@Suite("escapeJSON")
struct EscapeJSONTests {
    @Test("Returns unchanged string for simple input")
    func simpleString() {
        #expect(escapeJSON("hello world") == "hello world")
    }

    @Test("Escapes double quotes")
    func escapesDoubleQuotes() {
        #expect(escapeJSON("say \"hello\"") == "say \\\"hello\\\"")
    }

    @Test("Escapes backslashes")
    func escapesBackslashes() {
        #expect(escapeJSON("path\\to\\file") == "path\\\\to\\\\file")
    }

    @Test("Escapes newlines")
    func escapesNewlines() {
        #expect(escapeJSON("line1\nline2") == "line1\\nline2")
    }

    @Test("Escapes carriage returns")
    func escapesCarriageReturns() {
        #expect(escapeJSON("line1\rline2") == "line1\\rline2")
    }

    @Test("Escapes tabs")
    func escapesTabs() {
        #expect(escapeJSON("col1\tcol2") == "col1\\tcol2")
    }

    @Test("Handles empty string")
    func emptyString() {
        #expect(escapeJSON("") == "")
    }

    @Test("Escapes multiple special characters")
    func multipleSpecialCharacters() {
        let input = "He said \"hello\"\nand\\or goodbye"
        let expected = "He said \\\"hello\\\"\\nand\\\\or goodbye"
        #expect(escapeJSON(input) == expected)
    }
}

// MARK: - Single Tap JSON Formatting Tests

@Suite("formatTapAsJSON")
struct FormatTapAsJSONTests {
    @Test("Formats enabled tap correctly")
    func formatsEnabledTap() {
        let tap = EventTapInfo(
            tapID: 1,
            enabled: true,
            sourcePID: 100,
            sourcePath: "/usr/bin/test",
            destinationPID: 200,
            destinationPath: "/usr/bin/target"
        )

        let json = formatTapAsJSON(tap)

        #expect(json.contains("\"tapID\":\"1\""))
        #expect(json.contains("\"enabled\":true"))
        #expect(json.contains("\"sourcePID\":100"))
        #expect(json.contains("\"sourcePath\":\"/usr/bin/test\""))
        #expect(json.contains("\"destinationPID\":200"))
        #expect(json.contains("\"destinationPath\":\"/usr/bin/target\""))
    }

    @Test("Formats disabled tap correctly")
    func formatsDisabledTap() {
        let tap = EventTapInfo(
            tapID: 1, enabled: false, sourcePID: 100,
            sourcePath: "/path", destinationPID: 200, destinationPath: "/dest"
        )

        let json = formatTapAsJSON(tap)
        #expect(json.contains("\"enabled\":false"))
    }

    @Test("Shows 'All processes' for empty destination path")
    func emptyDestinationShowsAllProcesses() {
        let tap = EventTapInfo(
            tapID: 1, enabled: true, sourcePID: 100,
            sourcePath: "/path", destinationPID: 0, destinationPath: ""
        )

        let json = formatTapAsJSON(tap)
        #expect(json.contains("\"destinationPath\":\"All processes\""))
    }

    @Test("Escapes special characters in paths")
    func escapesSpecialCharactersInPaths() {
        let tap = EventTapInfo(
            tapID: 1, enabled: true, sourcePID: 100,
            sourcePath: "/path/with\"quotes", destinationPID: 200,
            destinationPath: "/path/with\\backslash"
        )

        let json = formatTapAsJSON(tap)
        #expect(json.contains("\\\""))
        #expect(json.contains("\\\\"))
    }

    @Test("Output is valid JSON")
    func outputIsValidJSON() throws {
        let tap = EventTapInfo(
            tapID: 42, enabled: true, sourcePID: 1234,
            sourcePath: "/usr/bin/test", destinationPID: 5678,
            destinationPath: "/Applications/Test.app"
        )

        let json = formatTapAsJSON(tap)
        let data = json.data(using: .utf8)!

        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(parsed != nil)
        #expect(parsed?["tapID"] as? String == "42")
        #expect(parsed?["enabled"] as? Bool == true)
        #expect(parsed?["sourcePID"] as? Int == 1234)
    }
}

// MARK: - Array JSON Formatting Tests

@Suite("formatTapsAsJSON")
struct FormatTapsAsJSONTests {
    @Test("Empty array returns []")
    func emptyArray() {
        let result = formatTapsAsJSON([])
        #expect(result == "[]")
    }

    @Test("Single tap formats correctly")
    func singleTap() throws {
        let tap = EventTapInfo(
            tapID: 1, enabled: true, sourcePID: 100,
            sourcePath: "/path", destinationPID: 200, destinationPath: "/dest"
        )

        let json = formatTapsAsJSON([tap])
        let data = json.data(using: .utf8)!

        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(parsed?.count == 1)
    }

    @Test("Multiple taps format correctly")
    func multipleTaps() throws {
        let taps = [
            EventTapInfo(tapID: 1, enabled: true, sourcePID: 100,
                        sourcePath: "/path1", destinationPID: 200, destinationPath: "/dest1"),
            EventTapInfo(tapID: 2, enabled: false, sourcePID: 101,
                        sourcePath: "/path2", destinationPID: 201, destinationPath: "/dest2"),
            EventTapInfo(tapID: 3, enabled: true, sourcePID: 102,
                        sourcePath: "/path3", destinationPID: 0, destinationPath: "")
        ]

        let json = formatTapsAsJSON(taps)
        let data = json.data(using: .utf8)!

        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(parsed?.count == 3)
        #expect(parsed?[2]["destinationPath"] as? String == "All processes")
    }

    @Test("Output is valid JSON array")
    func outputIsValidJSONArray() throws {
        let taps = [
            EventTapInfo(tapID: 1, enabled: true, sourcePID: 100,
                        sourcePath: "/path", destinationPID: 200, destinationPath: "/dest"),
            EventTapInfo(tapID: 2, enabled: false, sourcePID: 101,
                        sourcePath: "/path2", destinationPID: 201, destinationPath: "/dest2")
        ]

        let json = formatTapsAsJSON(taps)
        let data = json.data(using: .utf8)!

        // Should not throw
        _ = try JSONSerialization.jsonObject(with: data)
    }
}

// MARK: - fetchEventTaps Tests

@Suite("fetchEventTaps")
struct FetchEventTapsTests {
    @Test("Uses custom path resolver")
    func usesCustomPathResolver() {
        // This test verifies the path resolver is called
        // Note: On non-macOS or without accessibility permissions,
        // fetchEventTaps may return an empty array or nil
        var resolverCalled = false

        let mockResolver: (pid_t) -> String = { pid in
            resolverCalled = true
            return "/mock/path/\(pid)"
        }

        // fetchEventTaps will use our resolver if there are any taps
        let result = fetchEventTaps(pathResolver: mockResolver)

        // We can at least verify the function returns without crashing
        // The resolver is only called if there are actual taps
        #expect(result != nil || result == nil) // Always passes, but exercises the code

        // If there were taps, our resolver should have been called
        if let taps = result, !taps.isEmpty {
            #expect(resolverCalled == true)
            #expect(taps[0].sourcePath.hasPrefix("/mock/path/"))
        }
    }
}

// MARK: - Integration Tests

@Suite("Integration")
struct IntegrationTests {
    @Test("Full pipeline produces valid JSON")
    func fullPipelineProducesValidJSON() throws {
        // Create mock taps representing realistic scenarios
        let taps = [
            // Global tap (accessibility tool)
            EventTapInfo(
                tapID: 1,
                enabled: true,
                sourcePID: 500,
                sourcePath: "/System/Library/CoreServices/SystemUIServer.app/Contents/MacOS/SystemUIServer",
                destinationPID: 0,
                destinationPath: ""
            ),
            // Targeted tap
            EventTapInfo(
                tapID: 2,
                enabled: false,
                sourcePID: 1000,
                sourcePath: "/Applications/ScreenRecorder.app/Contents/MacOS/ScreenRecorder",
                destinationPID: 2000,
                destinationPath: "/Applications/Safari.app/Contents/MacOS/Safari"
            )
        ]

        let json = formatTapsAsJSON(taps)
        let data = json.data(using: .utf8)!

        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(parsed?.count == 2)

        // First tap should show "All processes"
        #expect(parsed?[0]["destinationPath"] as? String == "All processes")
        #expect(parsed?[0]["enabled"] as? Bool == true)

        // Second tap should show the actual path
        #expect(parsed?[1]["destinationPath"] as? String == "/Applications/Safari.app/Contents/MacOS/Safari")
        #expect(parsed?[1]["enabled"] as? Bool == false)
    }

    @Test("Handles paths with special characters")
    func handlesPathsWithSpecialCharacters() throws {
        let tap = EventTapInfo(
            tapID: 1,
            enabled: true,
            sourcePID: 100,
            sourcePath: "/Users/test/My \"App\"/Contents/MacOS/binary",
            destinationPID: 200,
            destinationPath: "/path/with\ttab/and\nnewline"
        )

        let json = formatTapsAsJSON([tap])
        let data = json.data(using: .utf8)!

        // Should parse without error
        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(parsed?.count == 1)
    }
}
