// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DJQuotesPDF",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "DJQuotesPDF", targets: ["DJQuotesPDF"]),
    ],
    targets: [
        .target(name: "DJQuotesPDF"),
    ]
)