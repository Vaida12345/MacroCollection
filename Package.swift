// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "NucleusMacros",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NucleusMacros",
            targets: ["NucleusMacros"]
        ),
        .executable(
            name: "macroRoom",
            targets: ["macroRoom"]
        ),
        .executable(
            name: "macroClient",
            targets: ["macroClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "NucleusMacrosDefinitions",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
        .target(name: "NucleusMacros", dependencies: ["NucleusMacrosDefinitions"]),
        
        .executableTarget(name: "macroRoom", dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
        ]),
        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "macroClient", dependencies: ["NucleusMacros"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "NucleusMacrosTests",
            dependencies: [
                "NucleusMacrosDefinitions",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
