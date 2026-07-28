// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "AngelNotch",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "AngelNotch", targets: ["AngelNotch"])
  ],
  targets: [
    .executableTarget(
      name: "AngelNotch",
      dependencies: ["AngelNotchServiceBridge"],
      path: "sources/angelnotch"
    ),
    .target(
      name: "AngelNotchServiceBridge",
      path: "sources/angelnotch-service-bridge",
      publicHeadersPath: "include",
      linkerSettings: [
        .linkedFramework("ServiceManagement")
      ]
    ),
  ]
)
