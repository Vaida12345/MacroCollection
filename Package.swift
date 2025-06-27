// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package (
    name: "MacroCollection",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16)
    ], products: [
        .library(name: "MacroCollection", targets: ["MacroCollection"])
    ], dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "601.0.0"),
        .package(url: "https://github.com/Vaida12345/MacroEssentials", from: "1.0.0")
    ], targets: [
        .macro(name: "MacrosDefinitions",
               dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                "MacroEssentials"
               ]),
        .target(name: "MacroCollection", dependencies: ["MacrosDefinitions"], path: "Sources/Macros"),
        
        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "macroClient", dependencies: ["MacroCollection"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "Tests",
            dependencies: [
                "MacrosDefinitions",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
