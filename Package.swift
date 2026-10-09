// swift-tools-version: 6.3

import PackageDescription

let package = Package(
	name: "IPtProxyUI",
	defaultLocalization: "en",
	platforms: [.iOS(.v15), .macOS(.v12)],
	products: [
		.library(
			name: "IPtProxyUI-macOS",
			targets: ["IPtProxyUI-macOS"]),
		.library(
			name: "IPtProxyUI-iOS-AppEx",
			targets: ["IPtProxyUI-iOS-AppEx"]),
		.library(
			name: "IPtProxyUI-iOS",
			targets: ["IPtProxyUI-iOS"])
	],
	dependencies: [
		.package(url: "https://github.com/tladesignz/IPtProxy.git", from: "5.7.0"),
		.package(url: "https://github.com/xmartlabs/eureka.git", from: "5.5.0"),
		.package(url: "https://github.com/relatedcode/ProgressHUD.git", from: "14.1.5"),
	],
	targets: [
		.target(
			name: "IPtProxyUI-Shared",
			dependencies: ["IPtProxy"],
			resources: [
				.process("Resources")
			],
			packageAccess: false,
			linkerSettings: [.linkedLibrary("resolv")]),
		.target(
			name: "IPtProxyUI-macOS-ObjC",
			publicHeadersPath: "include",
			packageAccess: false),
		.target(
			name: "IPtProxyUI-macOS",
			dependencies: [
				"IPtProxyUI-Shared",
				"IPtProxyUI-macOS-ObjC"]),
		.target(
			name: "IPtProxyUI-iOS-AppEx",
			dependencies: [
				"IPtProxyUI-Shared",
				.product(name: "Eureka", package: "eureka")]),
		.target(
			name: "IPtProxyUI-iOS",
			dependencies: [
				"IPtProxyUI-iOS-AppEx",
				.product(name: "Eureka", package: "eureka"),
				"ProgressHUD",
			]),
	],
	swiftLanguageModes: [.v5]
)
