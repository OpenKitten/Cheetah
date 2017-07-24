// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription

let package = Package(
    name: "Cheetah",
    products: [
        // Products define the executables and libraries produced by a package, and make them visib$
        .library(
            name: "Cheetah",
            targets: ["Cheetah"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a te$
        // Targets can depend on other targets in this package, and on products in packages which t$
        .target(
            name: "Cheetah"),
        .testTarget(
            name: "CheetahTests",
            dependencies: ["Cheetah"]),
    ]
)
