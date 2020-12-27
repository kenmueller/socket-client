// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "socket",
	platforms: [
		.iOS(.v13),
		.macOS(.v10_15),
		.tvOS(.v13),
		.watchOS(.v6)
	],
	products: [
		.library(name: "Socket", targets: ["Socket"])
	],
	targets: [
		.target(name: "Socket", dependencies: [])
	]
)
