// swift-tools-version: 5.8.1

import PackageDescription

let package = Package(
    name: "rum-models-generator",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.0"),
        .package(url: "https://github.com/krzysztofzablocki/Difference.git", from: "0.5.0"),
    ],
    targets: [
        // CLI wrapper
        .target(
            name: "rum-models-generator",
            dependencies: [
                "CodeGeneration",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "rum-models-generatorTests",
            dependencies: ["rum-models-generator",]
        ),

        // Product-agnostic code generator (JSON Schema -> Swift | Objc-interop)
        .target(
            name: "CodeGeneration",
            dependencies: []
        ),
        .testTarget(
            name: "CodeGenerationTests",
            dependencies: [
                "CodeGeneration",
                "Difference"
            ],
            resources: [.copy("Fixtures")]
        ),

        // Product-specific code decorators
        .target(
            name: "CodeDecoration",
            dependencies: ["CodeGeneration"]
        ),
    ]
)
