// swift-tools-version: 5.9
import PackageDescription

// The composition root is the only package allowed to know every feature. The edges run
// one way: features depend on CoreKit, RouterKit and DesignKit; AppCore depends on the
// features. No feature manifest lists AppCore, so the cycle cannot be written.
let package = Package(
    name: "AppCore",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "AppCore", targets: ["AppCore"])
    ],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../RouterKit"),
        .package(path: "../DesignKit"),
        .package(path: "../NetworkKit"),
        .package(path: "../FeatureSample")
    ],
    targets: [
        .target(
            name: "AppCore",
            dependencies: [
                .product(name: "CoreKit", package: "CoreKit"),
                .product(name: "RouterKit", package: "RouterKit"),
                .product(name: "DesignKit", package: "DesignKit"),
                .product(name: "NetworkKit", package: "NetworkKit"),
                .product(name: "FeatureSample", package: "FeatureSample")
            ]
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: [
                "AppCore",
                .product(name: "RouterKit", package: "RouterKit"),
                .product(name: "FeatureSample", package: "FeatureSample"),
                .product(name: "CoreKitTestSupport", package: "CoreKit")
            ]
        )
    ]
)
