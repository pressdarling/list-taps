import Foundation
import ApplicationServices
import Darwin

// Resolve executable path for a PID using libproc.
func pathForPID(_ pid: pid_t) -> String {
    var buf = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
    let n = proc_pidpath(pid, &buf, UInt32(buf.count))
    return n > 0 ? String(cString: buf) : ""
}

struct Tap: Codable {
    let tapID: UInt64
    let enabled: Bool
    let sourcePID: Int32
    let sourcePath: String
    let destinationPID: Int32
    let destinationPath: String
}

func getTaps() -> [Tap] {
    var count: UInt32 = 0
    guard CGGetEventTapList(0, nil, &count) == .success, count > 0 else { return [] }
    let buf = UnsafeMutablePointer<CGEventTapInformation>.allocate(capacity: Int(count))
    defer { buf.deallocate() }
    guard CGGetEventTapList(count, buf, &count) == .success else { return [] }

    var out: [Tap] = []
    for i in 0..<Int(count) {
        let t = buf[i]
        let srcPID = pid_t(t.tappingProcessID)
        let dstPID = pid_t(t.processID)
        let srcPath = pathForPID(srcPID)
        let dstPath = (dstPID == 0) ? "All processes" : pathForPID(dstPID)
        out.append(Tap(
            tapID: t.eventTapID,
            enabled: t.enabled != 0,
            sourcePID: t.tappingProcessID,
            sourcePath: srcPath,
            destinationPID: t.processID,
            destinationPath: dstPath
        ))
    }
    return out
}

let jsonOut = CommandLine.arguments.contains("--json")
let taps = getTaps()

if jsonOut {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? enc.encode(taps) else {
        fputs("Error: Failed to encode taps to JSON\n", stderr)
        exit(1)
    }
    FileHandle.standardOutput.write(data)
    if let newline = "\n".data(using: .utf8) {
        FileHandle.standardOutput.write(newline)
    }
} else {
    if taps.isEmpty {
        print("[]  (no event taps)")
    } else {
        for t in taps {
            print("#\(t.tapID)  \(t.enabled ? "[ENABLED]" : "[disabled]")")
            print("  source: \(t.sourcePID)  \(t.sourcePath)")
            print("  dest:   \(t.destinationPID)  \(t.destinationPath)")
        }
    }
}
