import PackageDescription

let package = Package(
    name: "Cheetah",
    dependencies: [
        .Package(url: "https://github.com/OpenKitten/KittenCore.git", majorVersion: 0, minor: 2)
    ]
)
