// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "socket",
	platforms: [
		.macOS(.v10_15)
	],
	products: [
		.library(name: "Socket", targets: ["Socket"])
	],
	targets: [
		.target(name: "Socket", dependencies: [])
	]
)
