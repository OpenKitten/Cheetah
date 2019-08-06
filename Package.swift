// swift-tools-version:4.0
import PackageDescription

var package = Package(
    name: "Cheetah"
)

#if swift(>=3.1)
package.swiftLanguageVersions = [3, 4]
#endif
