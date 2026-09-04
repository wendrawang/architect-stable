// swift-tools-version: 5.9
import PackageDescription

// Dependency edges are enforced here, not by convention: this manifest cannot see
// AppCore or any other feature package, so a cross-feature import cannot compile.
let package = Package(
    name: "FeatureSample",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "FeatureSample", targets: ["FeatureSample"])
    ],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../RouterKit"),
        .package(path: "../DesignKit")
    ],
    targets: [
        .target(
            name: "FeatureSample",
            dependencies: [
                .product(name: "CoreKit", package: "CoreKit"),
                .product(name: "RouterKit", package: "RouterKit"),
                .product(name: "DesignKit", package: "DesignKit")
            ]
        ),
        .testTarget(
            name: "FeatureSampleTests",
            dependencies: [
                "FeatureSample",
                .product(name: "CoreKit", package: "CoreKit"),
                .product(name: "RouterKit", package: "RouterKit"),
                .product(name: "CoreKitTestSupport", package: "CoreKit")
            ]
        )
    ]
)
