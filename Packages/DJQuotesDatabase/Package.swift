// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DJQuotesDatabase",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "DJQuotesDatabase", targets: ["DJQuotesDatabase"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "DJQuotesDatabase",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
    ]
)