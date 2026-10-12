// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DJQuotesPDF",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "DJQuotesPDF", targets: ["DJQuotesPDF"]),
    ],
    dependencies: [
        .package(path: "../DJQuotesDatabase"),
        .package(path: "../DJQuotesDomain"),
    ],
    targets: [
        .target(
            name: "DJQuotesPDF",
            dependencies: [
                .product(name: "DJQuotesDatabase", package: "DJQuotesDatabase"),
                .product(name: "DJQuotesDomain", package: "DJQuotesDomain"),
            ]
        ),
    ]
)