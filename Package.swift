// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftonizeExecutable",
	platforms: [.macOS(.v11)],
	dependencies: [
		.package(url: "https://github.com/PythonSwiftLink/PythonLib", from: "0.1.0"),
		.package(url: "https://github.com/PythonSwiftLink/PythonSwiftCore", branch: "testing"),
		//.package(path: "../Swiftonize"),
		.package(url: "https://github.com/PythonSwiftLink/Swiftonize", branch: "testing"),
		.package(url: "https://github.com/kylef/PathKit", from: .init(1, 0, 0) ),
		.package(url: "https://github.com/apple/swift-syntax", from: .init(508, 0, 0) ),
		
		
		.package(url: "https://github.com/apple/swift-argument-parser", from: .init(1, 2, 0))
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SwiftonizeExecutable",
			dependencies: [
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"PythonSwiftCore",
				"Swiftonize",
				"PathKit"
			]
		),
    ]
)
