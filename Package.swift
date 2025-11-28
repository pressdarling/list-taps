// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "list-taps",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "list-taps", targets: ["list-taps"])
    ],
    targets: [
        .executableTarget(
            name: "list-taps",
            path: "Sources/list-taps",
            linkerSettings: [
                .linkedFramework("ApplicationServices")
            ]
        ),
        .testTarget(
            name: "list-tapsTests",
            path: "Tests/list-tapsTests"
        )
    ]
)
