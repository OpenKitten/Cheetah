// swift-tools-version:4.0
import PackageDescription

var package = Package(
    name: "Cheetah",
    products: [
        .library(name: "Cheetah", targets: ["Cheetah"])
    ],
    dependencies: [
        .package(url: "https://github.com/OpenKitten/KittenCore.git", .revision("0.2.4-swift5")),
    ],
    targets: [
        .target(name: "Cheetah", dependencies: ["KittenCore"])
    ]
)
