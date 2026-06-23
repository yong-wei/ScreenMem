// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenMem",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ScreenMem", targets: ["ScreenMem"]),
        .executable(name: "ScreenMemShellChecks", targets: ["ScreenMemShellChecks"]),
        .library(name: "ScreenMemCore", targets: ["ScreenMemCore"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenMem",
            dependencies: ["ScreenMemCore"],
            path: "Sources/ScreenMemApp"
        ),
        .target(
            name: "ScreenMemCore",
            path: "Sources/ScreenMemCore"
        ),
        .executableTarget(
            name: "ScreenMemShellChecks",
            dependencies: ["ScreenMemCore"],
            path: "Tools/ScreenMemShellChecks"
        )
    ]
)
