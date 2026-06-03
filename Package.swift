// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OCRLatex",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OCRLatex", targets: ["OCRLatex"])
    ],
    targets: [
        .executableTarget(
            name: "OCRLatex",
            path: "Sources/OCRLatex"
        )
    ]
)
