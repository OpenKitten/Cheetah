// swift-tools-version:3.0
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription

var package = Package(
    name: "Cheetah"
)

#if swift(>=3.1)
package.swiftLanguageVersions = [3, 4]
#endif
