// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrackpadWeight",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "TrackpadWeight",
            targets: ["TrackpadWeight"]
        )
    ],
    targets: [
        .executableTarget(
            name: "TrackpadWeight",
            dependencies: [],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("MultitouchSupport", .when(platforms: [.macOS])),
                .unsafeFlags([
                    "-Xlinker", "-F/System/Library/PrivateFrameworks",
                    "-Xlinker", "-framework", "-Xlinker", "MultitouchSupport"
                ], .when(platforms: [.macOS]))
            ]
        ),
        .testTarget(
            name: "TrackpadWeightTests",
            dependencies: ["TrackpadWeight"],
            path: "Tests"
        )
    ]
)