// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DJQuotesDomain",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "DJQuotesDomain", targets: ["DJQuotesDomain"]),
    ],
    targets: [
        .target(name: "DJQuotesDomain"),
        .testTarget(
            name: "DJQuotesDomainTests",
            dependencies: ["DJQuotesDomain"]
        ),
    ]
)