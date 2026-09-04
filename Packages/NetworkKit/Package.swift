// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetworkKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "NetworkKit", targets: ["NetworkKit"])
    ],
    dependencies: [
        .package(path: "../CoreKit")
    ],
    targets: [
        .target(
            name: "NetworkKit",
            dependencies: [.product(name: "CoreKit", package: "CoreKit")]
        )
    ]
)
