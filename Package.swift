// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RepositorySync",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RepositorySync",
            targets: ["RepositorySync"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift.git", .upToNextMinor(from: "20.0.3"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RepositorySync",
            dependencies: [
                .product(name: "RealmSwift", package: "realm-swift")
            ]
        ),
        .testTarget(
            name: "RepositorySyncTests",
            dependencies: ["RepositorySync"]
        ),
    ]
)
