// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DockWizardKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "DockCore", targets: ["DockCore"]),
        .library(name: "PresetCore", targets: ["PresetCore"]),
        .executable(name: "dockwizard", targets: ["dockwizard"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(name: "DockCore"),
        .target(name: "PresetCore", dependencies: ["DockCore"]),
        .executableTarget(
            name: "dockwizard",
            dependencies: [
                "DockCore",
                "PresetCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "DockCoreTests", dependencies: ["DockCore"]),
        .testTarget(name: "PresetCoreTests", dependencies: ["PresetCore"]),
    ]
)
