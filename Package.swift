// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Brage",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/johnsundell/files.git", from: "4.0.0"),
        .package(url: "https://github.com/JohnSundell/Ink.git", from: "0.5.0"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.14.0"),
        .package(url: "https://github.com/behrang/YamlSwift.git", from: "3.4.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BrageCore",
            dependencies: ["Files", "Ink", "Stencil", "Yaml"]),
        .target(
            name: "Brage",
            dependencies: ["BrageCore"]),
        .testTarget(
            name: "BrageTests",
            dependencies: ["BrageCore"]),
    ]
)
