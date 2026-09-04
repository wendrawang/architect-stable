// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RouterKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "RouterKit", targets: ["RouterKit"])
    ],
    dependencies: [
        .package(path: "../CoreKit")
    ],
    targets: [
        .target(
            name: "RouterKit",
            dependencies: [.product(name: "CoreKit", package: "CoreKit")]
        ),
        .testTarget(
            name: "RouterKitTests",
            dependencies: [
                "RouterKit",
                .product(name: "CoreKit", package: "CoreKit"),
                .product(name: "CoreKitTestSupport", package: "CoreKit")
            ]
        ),
        .testTarget(
            name: "RouterKitPerformanceTests",
            dependencies: [
                "RouterKit",
                .product(name: "CoreKit", package: "CoreKit")
            ]
        )
    ]
)
