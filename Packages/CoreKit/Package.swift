// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoreKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "CoreKit", targets: ["CoreKit"]),
        .library(name: "CoreKitTestSupport", targets: ["CoreKitTestSupport"])
    ],
    targets: [
        .target(name: "CoreKit"),
        .target(name: "CoreKitTestSupport", dependencies: ["CoreKit"]),
        .testTarget(name: "CoreKitTests", dependencies: ["CoreKit", "CoreKitTestSupport"])
    ]
)
