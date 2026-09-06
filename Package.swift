// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AIUsageMeter",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MeterCore", targets: ["MeterCore"]),
        .executable(name: "ai-usage-meter-hook", targets: ["MeterHook"]),
        .executable(name: "ai-usage-meter-codex-hook", targets: ["MeterCodexHook"]),
        .executable(name: "AIUsageMeter", targets: ["AIUsageMeter"]),
    ],
    targets: [
        .target(name: "MeterCore"),
        .executableTarget(name: "MeterHook", dependencies: ["MeterCore"]),
        .executableTarget(name: "MeterCodexHook", dependencies: ["MeterCore"]),
        .executableTarget(name: "AIUsageMeter", dependencies: ["MeterCore"]),
        .testTarget(name: "MeterCoreTests", dependencies: ["MeterCore"]),
    ]
)
