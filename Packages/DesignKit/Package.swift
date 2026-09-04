// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DesignKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "DesignKit", targets: ["DesignKit"])
    ],
    dependencies: [
        .package(path: "../CoreKit")
    ],
    targets: [
        .target(
            name: "DesignKit",
            dependencies: [.product(name: "CoreKit", package: "CoreKit")]
        )
    ]
)
