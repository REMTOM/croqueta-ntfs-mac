// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CroquetaNTFS",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "CroquetaNTFS",
            path: "Sources/CroquetaNTFS",
            linkerSettings: [.linkedFramework("DiskArbitration")]
        )
    ]
)
