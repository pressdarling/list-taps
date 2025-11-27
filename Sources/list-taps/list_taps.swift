// The Swift Programming Language
// https://docs.swift.org/swift-book
// list_taps.swift
import Foundation
import ApplicationServices
import Darwin

var count: UInt32 = 0
guard CGGetEventTapList(0, nil, &count) == .success, count > 0 else {
    print("[]"); exit(0)
}
let buf = UnsafeMutablePointer<CGEventTapInformation>.allocate(capacity: Int(count))
defer { buf.deallocate() }
guard CGGetEventTapList(count, buf, &count) == .success else { exit(1) }

func pathForPID(_ pid: pid_t) -> String {
    var p = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
    let n = proc_pidpath(pid, &p, UInt32(p.count))
    return n > 0 ? String(cString: p) : ""
}

print("[")
for i in 0..<Int(count) {
    let t = buf[i]
    let srcPID = pid_t(t.tappingProcessID)
    let dstPID = pid_t(t.processID)
    let srcPath = pathForPID(srcPID)
    let dstPath = pathForPID(dstPID)
    let enabled = (t.enabled != 0)
    let dict = [
        "\"tapID\":\"\(t.eventTapID)\"",
        "\"enabled\":\(enabled ? "true" : "false")",
        "\"sourcePID\":\(t.tappingProcessID)",
        "\"sourcePath\":\"\(srcPath)\"",
        "\"destinationPID\":\(t.processID)",
        "\"destinationPath\":\"\(dstPath.isEmpty ? "All processes" : dstPath)\""
    ].joined(separator: ",")
    print("  {\(dict)}\(i == Int(count)-1 ? "" : ",")")
}
print("]")