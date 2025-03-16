// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWSimpleAI_Ollama",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "WWSimpleAI_Ollama", targets: ["WWSimpleAI_Ollama"]),
    ],
    dependencies: [
        .package(url: "https://github.com/William-Weng/WWNetworking.git", from: "1.7.5"),
    ],
    targets: [
        .target(name: "WWSimpleAI_Ollama", dependencies: ["WWNetworking"], resources: [.copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
