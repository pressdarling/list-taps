// The Swift Programming Language
// https://docs.swift.org/swift-book
// list_taps.swift
import Foundation
import ApplicationServices
import Darwin

// MARK: - Data Types

/// Represents information about an event tap
public struct EventTapInfo: Equatable, Sendable {
    public let tapID: UInt32
    public let enabled: Bool
    public let sourcePID: pid_t
    public let sourcePath: String
    public let destinationPID: pid_t
    public let destinationPath: String

    public init(
        tapID: UInt32,
        enabled: Bool,
        sourcePID: pid_t,
        sourcePath: String,
        destinationPID: pid_t,
        destinationPath: String
    ) {
        self.tapID = tapID
        self.enabled = enabled
        self.sourcePID = sourcePID
        self.sourcePath = sourcePath
        self.destinationPID = destinationPID
        self.destinationPath = destinationPath
    }
}

// MARK: - Path Resolution

/// Resolves a PID to its executable path
/// - Parameter pid: The process ID to resolve
/// - Returns: The executable path, or empty string if unavailable
public func pathForPID(_ pid: pid_t) -> String {
    var buffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
    let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
    return length > 0 ? String(cString: buffer) : ""
}

// MARK: - JSON Formatting

/// Escapes a string for safe JSON inclusion
/// - Parameter string: The string to escape
/// - Returns: The escaped string (without surrounding quotes)
public func escapeJSON(_ string: String) -> String {
    var result = ""
    for char in string {
        switch char {
        case "\"": result += "\\\""
        case "\\": result += "\\\\"
        case "\n": result += "\\n"
        case "\r": result += "\\r"
        case "\t": result += "\\t"
        default: result.append(char)
        }
    }
    return result
}

/// Formats a single EventTapInfo as a JSON object string
/// - Parameter tap: The event tap info to format
/// - Returns: A JSON object string (without trailing comma)
public func formatTapAsJSON(_ tap: EventTapInfo) -> String {
    let destinationDisplay = tap.destinationPath.isEmpty ? "All processes" : tap.destinationPath
    let fields = [
        "\"tapID\":\"\(tap.tapID)\"",
        "\"enabled\":\(tap.enabled)",
        "\"sourcePID\":\(tap.sourcePID)",
        "\"sourcePath\":\"\(escapeJSON(tap.sourcePath))\"",
        "\"destinationPID\":\(tap.destinationPID)",
        "\"destinationPath\":\"\(escapeJSON(destinationDisplay))\""
    ].joined(separator: ",")
    return "{\(fields)}"
}

/// Formats an array of EventTapInfo as a JSON array string
/// - Parameter taps: The event taps to format
/// - Returns: A formatted JSON array string
public func formatTapsAsJSON(_ taps: [EventTapInfo]) -> String {
    if taps.isEmpty {
        return "[]"
    }
    let items = taps.map { "  \(formatTapAsJSON($0))" }
    return "[\n\(items.joined(separator: ",\n"))\n]"
}

// MARK: - Event Tap Fetching

/// Fetches all active event taps from the system
/// - Parameter pathResolver: Function to resolve PIDs to paths (defaults to pathForPID)
/// - Returns: Array of EventTapInfo, or nil if the system call failed
public func fetchEventTaps(pathResolver: (pid_t) -> String = pathForPID) -> [EventTapInfo]? {
    var count: UInt32 = 0
    guard CGGetEventTapList(0, nil, &count) == .success else {
        return nil
    }

    if count == 0 {
        return []
    }

    let buffer = UnsafeMutablePointer<CGEventTapInformation>.allocate(capacity: Int(count))
    defer { buffer.deallocate() }

    guard CGGetEventTapList(count, buffer, &count) == .success else {
        return nil
    }

    var taps: [EventTapInfo] = []
    for i in 0..<Int(count) {
        let info = buffer[i]
        let srcPID = pid_t(info.tappingProcessID)
        let dstPID = pid_t(info.processID)

        taps.append(EventTapInfo(
            tapID: info.eventTapID,
            enabled: info.enabled != 0,
            sourcePID: srcPID,
            sourcePath: pathResolver(srcPID),
            destinationPID: dstPID,
            destinationPath: pathResolver(dstPID)
        ))
    }

    return taps
}

// MARK: - Main Entry Point

/// Main entry point for the list-taps tool
/// - Returns: Exit code (0 for success, 1 for failure)
@discardableResult
public func listTapsMain() -> Int32 {
    guard let taps = fetchEventTaps() else {
        return 1
    }
    print(formatTapsAsJSON(taps))
    return 0
}
