// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "m3ufrob",
    platforms: [
        // big surly is 11.4
        // Ventura 13.2.1
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "m3ufrob",
            targets: ["m3ufrob"]
        ),
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
        .package(url: "https://github.com/genedelisa/GDTerminalColor.git", from: "0.1.43")
        // local
        //.package(name: "GDTerminalColor",
        //                path: "../../../../Packages/GDTerminalColor")
    ],

    targets: [

      .executableTarget(
            name: "m3ufrob",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "GDTerminalColor", package: "GDTerminalColor")
            ],
            exclude: [
                "Resources/short.m3u"
            ],
            resources: [
                .process("Resources/help.txt")
            ],
            

            swiftSettings: [
                // @main bug
                // https://bugs.swift.org/browse/SR-12683
                // [path]/main.swift:11:1: 'main' attribute cannot be used in a module that contains top-level code
                .unsafeFlags(["-parse-as-library"]),
                // .unsafeFlags(["-parse-as-library", "-Onone"])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker",
                    "./SupportingFiles/m3ufrob/Info.plist",
                ]),
            ]),

        .testTarget(
            name: "m3ufrobTests",
            dependencies: [
              "m3ufrob"
            ]
        )
    ], // targets
    swiftLanguageVersions: [.v5]
)


#if swift(>=5.6)
package.dependencies += [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.2.0"),
]
#endif
