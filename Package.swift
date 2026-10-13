// swift-tools-version:5.7
import PackageDescription

// The progression model has no SpriteKit/UIKit dependency. This package
// exercises the same source files included by the Xcode app target.
let package = Package(
    name: "CubrismProgression",
    products: [.library(name: "CubrismProgression", targets: ["CubrismProgression"])],
    targets: [
        .target(name: "CubrismProgression", path: "Cubrism/Progression"),
        .testTarget(name: "DelveProgressionTests", dependencies: ["CubrismProgression"],
                    path: "Tests/DelveProgressionTests")
    ]
)
