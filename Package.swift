// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DJQuotes",
    platforms: [.iOS(.v18)],
    dependencies: [
        .package(path: "Packages/DJQuotesDatabase"),
        .package(path: "Packages/DJQuotesDomain"),
        .package(path: "Packages/DJQuotesPDF"),
    ],
    targets: [
        .executableTarget(
            name: "DJQuotes",
            dependencies: [
                .product(name: "DJQuotesDatabase", package: "DJQuotesDatabase"),
                .product(name: "DJQuotesDomain", package: "DJQuotesDomain"),
                .product(name: "DJQuotesPDF", package: "DJQuotesPDF"),
            ],
            path: "App/Sources/App",
            resources: [.process("Resources")]
        ),
    ]
)