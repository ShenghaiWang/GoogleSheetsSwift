// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoogleSheetsSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Main library product
        .library(
            name: "GoogleSheetsSwift",
            targets: ["GoogleSheetsSwift"]
        ),
    ],
    dependencies: [
        // No external dependencies to keep the SDK lightweight and secure
    ],
    targets: [
        // Main SDK target
        .target(
            name: "GoogleSheetsSwift",
            dependencies: [],
            path: "Sources/GoogleSheetsSwift",
            exclude: [
                // Exclude any non-source files if needed
            ],
            resources: [
                // No resources needed for this SDK
            ]
        ),
        // Test target
        .testTarget(
            name: "GoogleSheetsSwiftTests",
            dependencies: ["GoogleSheetsSwift"],
            path: "Tests/GoogleSheetsSwiftTests",
            exclude: [
                "Integration/README.md"
            ],
            resources: [
                // Test fixtures and resources
                .copy("Fixtures"),
                .copy("Integration")
            ]
        ),
        .executableTarget(name: "Client",
                          dependencies: [
                              "GoogleSheetsSwift",
                          ]),
    ],
    swiftLanguageVersions: [.v5]
)
